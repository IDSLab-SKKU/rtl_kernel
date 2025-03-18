/*
# Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
# SPDX-License-Identifier: X11
*/
#include <iostream>
#include <cstring>

// XRT includes
#include "xrt/xrt_bo.h"
#include "xrt/xrt_device.h"
#include <experimental/xrt_xclbin.h>
#include <experimental/xrt_ip.h>

#define DATA_SIZE 4096         //  33554432*2 , 256MB per 1 ch
#define IP_START 0x1
#define IP_DONE 0x2
#define IP_IDLE 0x4
#define USER_OFFSET 0x10
#define BYTE_LEN 0x14
#define SRC_ADDR 0x18
#define DST_ADDR 0x1c


int main(int argc, char** argv) {

    std::cout << "argc = " << argc << std::endl;
	for(int i=0; i < argc; i++){
	    std::cout << "argv[" << i << "] = " << argv[i] << std::endl;
	}

    // Read settings
	  std::string binaryFile = argv[1];
    auto xclbin = xrt::xclbin(binaryFile);
    int device_index = 0;

    std::cout << "Open the device " << device_index << std::endl;
    auto device = xrt::device(device_index);
    std::cout << "Load the xclbin " << binaryFile << std::endl;
    auto uuid = device.load_xclbin(binaryFile);
 
    size_t vector_size_bytes = sizeof(int) * DATA_SIZE;
    std::cout << "BYTE_LEN (Bytes): " << vector_size_bytes << std::endl;


    auto ip1 = xrt::ip(device, uuid, "DMAC_TOP:{DMAC_TOP_1}");
    

    
    std::cout << "Allocate Buffer in Global Memory\n";
    auto ip1_boA = xrt::bo(device, vector_size_bytes, 0); // use bank id 0, which is very important, because hbm bank 0 has been only mapped to this kernel
    auto ip1_boB = xrt::bo(device, vector_size_bytes, 1); // If you use other bank id ,  DMA will not operate normally. that's why i use bank 0


    // Map the contents of the buffer object into host memory

    auto bo0_map = ip1_boA.map<int*>();
    auto bo1_map = ip1_boB.map<int*>();


 
    std::fill(bo0_map, bo0_map + DATA_SIZE, 0);
    std::fill(bo1_map, bo1_map + DATA_SIZE, 0);


    // Create the test data

    for (int i = 0; i < DATA_SIZE; ++i) {
        bo0_map[i] = i;
   
        //Generate check data for validation
    }

/*
    for (int i = 0; i < DATA_SIZE; ++i) {
    	 std::cout << "src: " << bo0_map[i] << " dst: " << bo1_map[i] <<"\n";
    }
*/

    std::cout << "loaded the data" << std::endl;
    uint32_t buf_addr[16];
    // Get the buffer physical address
    buf_addr[0] = ip1_boA.address();
    buf_addr[1] = ip1_boB.address();


    std::cout << "SRC_ADDR (Physical): 0x" << std::hex << buf_addr[0] << std::endl;
    std::cout << "DST_ADDR (Physical): 0x" << std::hex << buf_addr[1] << std::endl;

    // Synchronize buffer content with device side
    std::cout << "synchronize input buffer data to device global memory\n";
    ip1_boA.sync(XCL_BO_SYNC_BO_TO_DEVICE);
    ip1_boB.sync(XCL_BO_SYNC_BO_TO_DEVICE);



    std::cout << "INFO: Setting IP Data" << std::endl;

    std::cout << "Setting Register \"BYTE_LEN\" (BYTE_LENTH)" << std::endl;
     ip1.write_register(BYTE_LEN, vector_size_bytes );

    std::cout << "Setting Register \"SRC_ADDR\" (Input Address)" << std::endl;
    ip1.write_register(SRC_ADDR, buf_addr[0]);

    std::cout << "Setting Register \"DST_ADDR\" (Input Address)" << std::endl;
    ip1.write_register(DST_ADDR, buf_addr[1]);

 
    uint32_t axi_ctrl = IP_START;
    std::cout << "INFO: IP Start" << std::endl;
    //axi_ctrl = IP_START;

    ip1.write_register(USER_OFFSET, axi_ctrl);


    uint32_t krnl_done;
    // Wait until the IP is DONE
    // Wait until the IP is DONE
    int i = 0;
    while (krnl_done != IP_DONE) {
        axi_ctrl = ip1.read_register(USER_OFFSET);
        krnl_done = axi_ctrl & 0xfffffff2;
        krnl_idle = axi_ctrl & 0xfffffff4;
        i = i + 1;
        std::cout << "Read Loop iteration: " << i << " Kernel Done: " << krnl_done << " Kernel Idle: " << krnl_idle << "\n";
    }
    
    std::cout << "INFO: IP Done" << std::endl;

    // Get the output;
    std::cout << "Get the output data from the device" << std::endl;
    ip1_boB.sync(XCL_BO_SYNC_BO_FROM_DEVICE);


/*
    for (int i = 0; i < DATA_SIZE; i++) {
        std::cout << std::dec << "src: " << bo0_map[i] << " dst: " << bo1_map[i] << "\n";
    }
*/


    std::cout << "SRC_ADDR (Physical): 0x" << std::hex << buf_addr[0] << std::endl;
    std::cout << "DST_ADDR (Physical): 0x" << std::hex << buf_addr[1] << std::endl;



    // Validate results
    if (std::memcmp(bo1_map, bo0_map, DATA_SIZE))
        throw std::runtime_error("Value read back does not match reference");


    std::cout << "TEST PASSED\n";
    return 0;
}
