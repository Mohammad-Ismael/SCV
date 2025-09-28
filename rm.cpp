// file: rm.cpp
#include "rm.h"
#include <iostream>
#include <cstdint>
#include <iomanip>

// Helper to normalize all inputs to RTL widths
inline void normalize_inputs(int32_t &op, int32_t &a, int32_t &b,
                             bool &carry_in, bool &sat_enable,
                             int32_t &cmp_mode, int32_t &shift_amt) {
    a        &= 0xFF;   // 8 bits
    b        &= 0xFF;   // 8 bits
    carry_in &= 0x1;    // 1 bit
    sat_enable &= 0x1;  // 1 bit
    op       &= 0x7;    // 3 bits
    cmp_mode &= 0x3;    // 2 bits
    shift_amt &= 0x7;   // 3 bits
}

int32_t RM::calculate_y(bool rst_n, bool en, int32_t op, int32_t a, int32_t b,
                        bool carry_in, bool sat_enable,
                        int32_t cmp_mode, int32_t shift_amt)
{
    if (!rst_n || !en) return 0;
    normalize_inputs(op, a, b, carry_in, sat_enable, cmp_mode, shift_amt);

    int32_t y = 0;
    int64_t add_ext = (int64_t)a + (int64_t)b + (int64_t)carry_in;
    int64_t sub_ext = (int64_t)a - (int64_t)b;

    switch (op) {
        case 0: // ADD
            if (sat_enable)
                y = (add_ext > 255) ? 255 : (int32_t)add_ext;
            else
                y = (int32_t)(add_ext & 0xFF);
            // std::cout << "[RM] ADD: " << a << " + " << b << " + carry(" << carry_in << ") = " << y << std::endl;
            break;

        case 1: // SUB
            if (sat_enable)
                y = (sub_ext < 0) ? 0 : (int32_t)sub_ext;
            else
                y = (int32_t)(sub_ext & 0xFF);
            // std::cout << "[RM] SUB: " << a << " - " << b << " = " << y << std::endl;
            break;

        case 2: y = (a & b) & 0xFF;
            // std::cout << "[RM] AND: " << a << " & " << b << " = " << y << std::endl;
            break;

        case 3: y = (a | b) & 0xFF;
            // std::cout << "[RM] OR: " << a << " | " << b << " = " << y << std::endl;
            break;

        case 4: y = (a ^ b) & 0xFF;
            // std::cout << "[RM] XOR: " << a << " ^ " << b << " = " << y << std::endl;
            break;

        case 5: y = (a << shift_amt) & 0xFF;
            // std::cout << "[RM] LSL: " << a << " << " << shift_amt << " = " << y << std::endl;
            break;

        case 6: y = ((uint32_t)a >> shift_amt) & 0xFF;
            // std::cout << "[RM] LSR: " << a << " >> " << shift_amt << " = " << y << std::endl;
            break;

        case 7: y = ((int32_t)a >> shift_amt) & 0xFF;
            // std::cout << "[RM] ASR: " << a << " >>> " << shift_amt << " = " << y << std::endl;
            break;

        default: y = 0;
            // std::cout << "[RM] UNKNOWN OP (" << op << ") → 0" << std::endl;
    }
    return y & 0xFF;
}

int32_t RM::calculate_carry_out(bool rst_n, bool en, int32_t op, int32_t a, int32_t b,
                                bool carry_in, bool sat_enable,
                                int32_t cmp_mode, int32_t shift_amt)
{
    if (!rst_n || !en) return 0;
    normalize_inputs(op, a, b, carry_in, sat_enable, cmp_mode, shift_amt);

    int64_t add_ext = (int64_t)a + (int64_t)b + (int64_t)carry_in;
    int64_t sub_ext = (int64_t)a - (int64_t)b;

    int32_t co = 0;
    switch (op) {
        case 0: co = (add_ext > 255) ? 1 : 0;
                // std::cout << "[RM] Carry(ADD) = " << co << std::endl; break;
        case 1: co = (sub_ext >= 0) ? 1 : 0;
                // std::cout << "[RM] Carry(SUB, no-borrow=1) = " << co << std::endl; break;
        default: co = 0;
    }
    return co;
}

int32_t RM::calculate_zero(bool rst_n, bool en, int32_t op, int32_t a, int32_t b,
                           bool carry_in, bool sat_enable,
                           int32_t cmp_mode, int32_t shift_amt)
{
    int32_t y = calculate_y(rst_n, en, op, a, b, carry_in, sat_enable, cmp_mode, shift_amt);
    int32_t z = (y == 0) ? 1 : 0;
    // std::cout << "[RM] ZERO flag = " << z << std::endl;
    return z;
}

int32_t RM::calculate_negative(bool rst_n, bool en, int32_t op, int32_t a, int32_t b,
                               bool carry_in, bool sat_enable,
                               int32_t cmp_mode, int32_t shift_amt)
{
    int32_t y = calculate_y(rst_n, en, op, a, b, carry_in, sat_enable, cmp_mode, shift_amt);
    int32_t n = ((y & 0x80) != 0) ? 1 : 0;
    // std::cout << "[RM] NEGATIVE flag = " << n << std::endl;
    return n;
}

int32_t RM::calculate_cmp_out(bool rst_n, bool en, int32_t op, int32_t a, int32_t b,
                              bool carry_in, bool sat_enable,
                              int32_t cmp_mode, int32_t shift_amt)
{
    if (!rst_n || !en) return 0;
    normalize_inputs(op, a, b, carry_in, sat_enable, cmp_mode, shift_amt);

    int32_t c = 0;
    switch (cmp_mode) {
        case 0: c = (a == b); 
        // std::cout << "[RM] CMP == : " << a << " vs " << b << " → " << c << std::endl; break;
        case 1: c = (a <  b); 
        // std::cout << "[RM] CMP <  : " << a << " vs " << b << " → " << c << std::endl; break;
        case 2: c = (a >  b); 
        // std::cout << "[RM] CMP >  : " << a << " vs " << b << " → " << c << std::endl; break;
        default: c = 0;       
        // std::cout << "[RM] CMP unknown mode → 0" << std::endl; break;
    }
    return c;
}



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