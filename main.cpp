// main.cpp (updated)
#include <systemc>
#include <tlm_utils/simple_initiator_socket.h>
#include <tlm_utils/simple_target_socket.h>
#include "stimulator.h"
#include "driver.h"
#include "rm.h"
#include "transactor.h"
#include "comparator.h" // Add this

int sc_main(int argc, char *argv[])
{
    sc_core::sc_report_handler::set_actions("/IEEE_Std_1666/deprecated", sc_core::SC_DO_NOTHING);
    std::string json_file = (argc > 1) ? argv[1] : "stimule/stimuli1.json";

    TimingController tc("timing_controller");

    Stimulator stim("stim");
    stim.set_params(json_file);
    stim.set_timing_controller(&tc);

    Driver driver("driver");
    RM rm("rm");
    Transactor transactor("transactor");
    Comparator comparator("comparator"); // New module

    transactor.set_timing_controller(&tc);

    sc_core::sc_fifo<CustomData> fifo;
    stim.out(fifo);
    driver.in(fifo);

    // Bind sockets
    driver.socket_rm.bind(rm.socket);
    driver.socket_transactor.bind(transactor.socket);
    
    // Bind comparator sockets
    rm.socket_comparator.bind(comparator.socket_rm);
    transactor.socket_comparator.bind(comparator.socket_rtl);

    sc_core::sc_start();
    return 0;
}