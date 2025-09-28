// timing_controller.h
#ifndef TIMING_CONTROLLER_H
#define TIMING_CONTROLLER_H

#include <systemc>

SC_MODULE(TimingController)
{
    // ⚙️ Centralized timing configuration
    const sc_core::sc_time CLOCK_PERIOD = sc_core::sc_time(5, sc_core::SC_NS); // ← Clock period
    const double CLOCK_DUTY_CYCLE = 0.5;       // 50%
    const sc_core::sc_time CLOCK_START_DELAY = sc_core::sc_time(0, sc_core::SC_NS);
    const bool CLOCK_POSITIVE_PULSE = true;

    const int OUTPUT_DELAY_CYCLES = 2;         // Cycles to wait for RTL output
    const sc_core::sc_time STIMULUS_INTERVAL = sc_core::sc_time(10, sc_core::SC_NS);

    // Events
    sc_core::sc_event inputs_ready_event;
    sc_core::sc_event outputs_ready_event;
    sc_core::sc_event next_stimulus_event;

    // Public clock signal (so Transactor can use it)
    sc_core::sc_clock clk;

    SC_CTOR(TimingController)
        : clk("global_clk", CLOCK_PERIOD, CLOCK_DUTY_CYCLE, CLOCK_START_DELAY, CLOCK_POSITIVE_PULSE)
    {
        SC_THREAD(stimulus_scheduler);
        SC_THREAD(rtl_output_scheduler);
    }

    void stimulus_scheduler()
    {
        while (true) {
            next_stimulus_event.notify(STIMULUS_INTERVAL);
            wait(next_stimulus_event);
        }
    }

    void rtl_output_scheduler()
    {
        while (true) {
            wait(inputs_ready_event);
            wait(OUTPUT_DELAY_CYCLES * CLOCK_PERIOD); // Scale with clock
            outputs_ready_event.notify();
        }
    }
};

#endif // TIMING_CONTROLLER_H