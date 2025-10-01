#!/usr/bin/env python3
# generate_dummy_rm.py

import os
import sys
import re

def parse_output_struct(output_struct_path):
    """Parse output_struct.h to extract output fields with exact names and types"""
    if not os.path.exists(output_struct_path):
        print(f"Error: {output_struct_path} not found!")
        sys.exit(1)
    
    with open(output_struct_path, 'r') as f:
        content = f.read()
    
    # Extract struct fields between { and }
    struct_match = re.search(r'struct OutputStruct\s*{([^}]*)}', content, re.DOTALL)
    if not struct_match:
        print(f"Error: Could not find OutputStruct definition in {output_struct_path}")
        sys.exit(1)
    
    fields_content = struct_match.group(1)
    # Match: type name;
    field_pattern = r'(\w+(?:\s*\*\s*)?)\s+(\w+)\s*;'
    fields = []
    
    for match in re.finditer(field_pattern, fields_content):
        field_type = match.group(1).strip()
        field_name = match.group(2)
        fields.append({'name': field_name, 'type': field_type})
    
    if not fields:
        print(f"Error: No fields found in OutputStruct")
        sys.exit(1)
    
    return fields

def generate_rm_h(output_ports, output_path):
    """Generate rm.h with dynamic outputs from OutputStruct"""
    
    # Create variable declarations (exactly as in OutputStruct)
    var_declarations = []
    for port in output_ports:
        var_declarations.append(f"        {port['type']} {port['name']} = 0;")
    
    # Create output struct assignments
    output_assignments = []
    for port in output_ports:
        output_assignments.append(f"        output.{port['name']} = {port['name']};")
    
    template = f"""#ifndef TARGET_H
#define TARGET_H

#include <systemc>
#include <tlm>
#include <tlm_utils/simple_initiator_socket.h>
#include <tlm_utils/simple_target_socket.h>
#include "custom_data.h"
#include "output_struct.h"
#include "debug.h"

#include <iostream> // for coloring

using namespace tlm_utils;
using namespace tlm;
using namespace sc_core;
using namespace std;

SC_MODULE(RM)
{{
    simple_target_socket<RM> socket;
    simple_initiator_socket<RM> socket_comparator; // New socket

    SC_CTOR(RM) : socket("socket"), socket_comparator("socket_comparator")
    {{
        socket.register_b_transport(this, &RM::b_transport);
    }}

    void b_transport(tlm_generic_payload & trans, sc_time & delay)
    {{
        if (trans.get_command() == tlm::TLM_IGNORE_COMMAND)
        {{
            trans.set_response_status(tlm::TLM_OK_RESPONSE);
            return;
        }}
        auto *buffer = trans.get_data_ptr();
        auto data = CustomData::deserialize(buffer);

        if constexpr (DEBUG_TLM)
        {{
            std::cout << sc_time_stamp() << " |     RM     | TLM | Received: " << data << std::endl;
        }}

        trans.set_response_status(tlm::TLM_OK_RESPONSE);
        
        // 🔴 DUMMY REFERENCE MODEL - AUTO-GENERATED 🔴
        // This is a placeholder RM. Replace with actual logic!
        
        // Initialize dummy outputs (dynamically generated from OutputStruct)
{chr(10).join(var_declarations)}

        OutputStruct output;
{chr(10).join(output_assignments)}
        send_to_comparator(output);
    }} 

    void send_to_comparator(const OutputStruct &output);
}};

#endif
"""
    
    with open(output_path, 'w') as f:
        f.write(template)
    print(f"✅ Generated dummy {output_path}")

def generate_rm_cpp(output_path):
    """Generate rm.cpp"""
    template = """// file: rm.cpp
// 🔴 DUMMY REFERENCE MODEL - AUTO-GENERATED 🔴
// This is a placeholder RM. Replace with actual logic!

#include "rm.h"

void RM::send_to_comparator(const OutputStruct &output)
{
    tlm_generic_payload trans;
    sc_time delay = SC_ZERO_TIME;
    trans.set_data_ptr(reinterpret_cast<unsigned char *>(const_cast<OutputStruct *>(&output)));
    trans.set_data_length(sizeof(OutputStruct));
    trans.set_command(TLM_WRITE_COMMAND);
    trans.set_response_status(TLM_INCOMPLETE_RESPONSE);
    socket_comparator->b_transport(trans, delay);
}
"""
    
    with open(output_path, 'w') as f:
        f.write(template)
    print(f"✅ Generated dummy {output_path}")

def main():
    if len(sys.argv) != 3:
        print("Usage: python3 generate_dummy_rm.py <output_struct.h path> <output_dir>")
        print("Example: python3 generate_dummy_rm.py output_struct.h .")
        sys.exit(1)
    
    output_struct_path = sys.argv[1]
    output_dir = sys.argv[2]
    
    rm_h_path = os.path.join(output_dir, "rm.h")
    rm_cpp_path = os.path.join(output_dir, "rm.cpp")
    
    # Check if files already exist
    rm_h_exists = os.path.exists(rm_h_path)
    rm_cpp_exists = os.path.exists(rm_cpp_path)
    
    if rm_h_exists and rm_cpp_exists:
        print("✅ RM files already exist. Skipping generation.")
        return
    
    if rm_h_exists or rm_cpp_exists:
        print("⚠️  Warning: Only one RM file exists. Regenerating both for consistency.")
    
    # Parse output structure
    output_ports = parse_output_struct(output_struct_path)
    print(f"Found {len(output_ports)} output fields from OutputStruct:")
    for port in output_ports:
        print(f"  - {port['name']} ({port['type']})")
    
    # Generate files
    generate_rm_h(output_ports, rm_h_path)
    generate_rm_cpp(rm_cpp_path)
    
    print("\n" + "="*60)
    print("🔴 DUMMY REFERENCE MODEL GENERATED!")
    print("⚠️  This is a placeholder RM with all outputs set to 0.")
    print("🔧 Replace the dummy logic in rm.h with your actual RM implementation.")
    print("="*60)

if __name__ == "__main__":
    main()