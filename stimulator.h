#ifndef STIMULATOR_H
#define STIMULATOR_H

#include <systemc>
#include <tlm>
#include <fstream>
#include <sstream>
#include <string>
#include <cstdlib>
#include <ctime>
#include <limits>
#include <map>
#include <vector>
#include "custom_data.h"
#include "rand_const.h"
#include "debug.h"
#include "timing_controller.h"

using namespace sc_core;
using namespace std;

SC_MODULE(Stimulator)
{
    TimingController *tc = nullptr; // ← Initialize to nullptr

    sc_core::sc_fifo_out<CustomData> out;
    std::string json_file;

    SC_CTOR(Stimulator) : out("out"), json_file("stimuli.json")
    {
        SC_THREAD(generate);
    }

    void set_timing_controller(TimingController * controller)
    {
        tc = controller;
    }

    void set_params(const std::string &file)
    {
        json_file = file;
    }

    void generate()
    {
        std::srand(std::time(NULL));
        std::ifstream file(json_file);
        if (!file)
        {
            SC_REPORT_ERROR("Stimulator", ("Cannot open " + json_file).c_str());
            return;
        }
        std::stringstream ss;
        ss << file.rdbuf();
        std::string json = ss.str();

        // Find tests array
        size_t pos = json.find("\"tests\"");
        if (pos == std::string::npos)
        {
            SC_REPORT_ERROR("Stimulator", "JSON must contain 'tests' array");
            return;
        }
        pos = json.find('[', pos);
        if (pos == std::string::npos)
        {
            SC_REPORT_ERROR("Stimulator", "Invalid 'tests' array");
            return;
        }

        // Count test cases
        size_t test_count = 0;
        size_t count_pos = pos + 1;
        int brace_count = 0;
        bool in_object = false;
        while (count_pos < json.length())
        {
            if (json[count_pos] == '{')
            {
                in_object = true;
                brace_count++;
            }
            else if (json[count_pos] == '}')
            {
                brace_count--;
                if (brace_count == 0 && in_object)
                {
                    test_count++;
                    in_object = false;
                }
            }
            count_pos++;
            if (brace_count == 0 && json[count_pos] == ']')
                break;
        }

        // Parse and send each test case
        size_t sent_count = 0;
        pos = pos + 1; // Move past '['
        while (sent_count < test_count && pos < json.length())
        {
            // Skip whitespace and commas
            while (pos < json.length() && (json[pos] == ' ' || json[pos] == '\n' || json[pos] == '\r' || json[pos] == '\t' || json[pos] == ','))
            {
                pos++;
            }
            if (pos >= json.length() || json[pos] != '{')
                break;

            CustomData data{};
            // Find end of object
            size_t end = pos;
            brace_count = 1;
            while (end < json.length() && brace_count > 0)
            {
                end++;
                if (json[end] == '{')
                    brace_count++;
                else if (json[end] == '}')
                    brace_count--;
            }
            if (brace_count != 0 || end >= json.length())
            {
                SC_REPORT_WARNING("Stimulator", "Invalid JSON object detected");
                break;
            }
            std::string test = json.substr(pos, end - pos + 1);

            // Parse all key-value pairs
            std::map<std::string, std::string> fields;
            size_t field_pos = test.find('"', 0);
            while (field_pos != std::string::npos && field_pos < test.length())
            {
                size_t key_end = test.find('"', field_pos + 1);
                if (key_end == std::string::npos)
                    break;
                std::string key = test.substr(field_pos + 1, key_end - field_pos - 1);
                size_t val_start = test.find(':', key_end) + 1;
                size_t val_end = test.find_first_of(",}", val_start);
                std::string value = test.substr(val_start, val_end - val_start);
                value.erase(0, value.find_first_not_of(" \n\r\t"));
                value.erase(value.find_last_not_of(" \n\r\t") + 1);
                fields[key] = value;
                field_pos = test.find('"', val_end);
            }

            // Map fields to CustomData dynamically
            bool valid = true;
            for (const auto &field : CustomData::get_fields())
            {
                if (fields.find(field.first) != fields.end())
                {
                    if (!CustomData::set_field(data, field.first, fields[field.first]))
                    {
                        valid = false;
                        break;
                    }
                }
            }
            if (valid)
            {
                wait(SC_ZERO_TIME);
                out.write(data);
                if constexpr (DEBUG_RTL || DEBUG_RM || DEBUG_TLM)
                {
                    if constexpr (DEBUG_TLM)
                    {
                        cout << "\n\033[1;32m======================= TLM Job Start =========================\033[0m" << endl;
                        std::cout << sc_time_stamp() << " | Stimulator | TLM | Pulled:   " << data << std::endl;
                    } else{
                        cout << "\n\033[1;32m======================= Test Case =========================\033[0m" << endl;
                        std::cout << sc_time_stamp() << " | Stimulator | TLM | Pulled:   " << data << std::endl;
                    }
                }
                sent_count++;
                wait(tc->next_stimulus_event);
            }
            else
            {
                SC_REPORT_WARNING("Stimulator", ("Failed to parse test case " + std::to_string(sent_count + 1)).c_str());
            }
            pos = end + 1;
        }

        // Wait for Driver and RM to process all FIFO entries
        sc_core::wait(sent_count * 2, sc_core::SC_NS); // Conservative delay based on test cases

        // Stop simulation after all test cases
        if (sent_count == test_count)
        {
            std::cout << "All Cases Are Tested" << std::endl;
            sc_core::sc_stop();
        }
        else
        {
            SC_REPORT_WARNING("Stimulator", ("Only " + std::to_string(sent_count) + " of " + std::to_string(test_count) + " test cases sent").c_str());
            sc_core::sc_stop();
        }
    }
};

#endif