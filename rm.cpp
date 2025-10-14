// file: rm.cpp
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
