-------------------------------------------------------------------------------
-- HEIG-VD, Haute Ecole d'Ingenierie et de Gestion du canton de Vaud
-- Institut REDS, Reconfigurable & Embedded Digital Systems
--
-- File         : logger_pkg.vhd
-- Description  : Package that declares a protected type for logging and
--                reporting, every entry is marked by a timestamp. A summary of
--                total warnings, errors and failures is appended at the end.
--
-- Author       : Rick Wertenbroek
-- Date         : 28.02.18
-- Version      : 0.0
--
-- Dependencies :
--
--| Modifications |------------------------------------------------------------
-- Version   Author Date               Description
-- 0.0       RWE    28.02.18           Creation
-- 1.0       YTA    09.09.22           Some cosmetic modifications
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use work.html_report_pkg.all;

-------------------------
-- Package Declaration --
-------------------------
package logger_pkg is

    ------------
    -- Logger --
    ------------
    type logger_t is protected

        -- When called with a filename will open the file and write all
        -- subsequent log messages to the file specified by the filename.
        procedure enable_log_to_file(filename : string := "log.txt"; mode : file_open_kind := write_mode);

        -- Sets the verbosity, any logging messages below the severity given as
        -- a parameter will be muted.
        procedure set_verbosity(constant severity_i : severity_level := note);

        -- Logs a note
        procedure log_note(message : string := "");

        -- Logs a warning
        procedure log_warning(message : string := "");

        -- Logs an error
        procedure log_error(message : string := "");

        -- Logs a failure
        procedure log_failure(message : string := "");

        -- Prints a final report (also appended to file if logging to file is
        -- enabled).
        procedure final_report;

    end protected logger_t;

end logger_pkg;

------------------
-- Package Body --
------------------
package body logger_pkg is

    ------------
    -- Logger --
    ------------
    type logger_t is protected body

        --------------------
        -- Internal Types --
        --------------------
        type string_ptr_t is access string;

        ------------------------
        -- Internal Variables --
        ------------------------
        variable nb_notes           : natural := 0;
        variable nb_warnings        : natural := 0;
        variable nb_errors          : natural := 0;

        variable verbosity_severity : severity_level := note;
        variable file_status        : file_open_status := status_error;
        file output_file            : TEXT;

        -------------------------
        -- Internal Procedures --
        -------------------------
        procedure write_to_file(constant string_c : string; constant severity_i : severity_level := note) is
            variable l : line;
        begin
            -- Only write to the file if it is open
            if file_status = open_ok then
                html_report(output_file, string_c, severity_i);
            end if;
        end write_to_file;

        procedure logger_report(constant message : string; constant severity_i : severity_level := note) is
            -- Add a timestamp to the message.
            variable timed_message : string_ptr_t := new string'(" @ " & time'image(now) & " " & message);
            variable effective_message : string_ptr_t;
        begin

            -- Generate a message with an appropriate label.
            case severity_i is
                when note =>
                    effective_message := new string'("[NOTE]" & timed_message.all);
                when warning =>
                    effective_message := new string'("[WARNING]" & timed_message.all);
                when error =>
                    effective_message := new string'("[ERROR]" & timed_message.all);
                when failure =>
                    effective_message := new string'("[FAILURE]" & timed_message.all);
            end case;

            -- Report the message and if the file is open write to file.
            report effective_message.all severity severity_i;
            write_to_file(effective_message.all, severity_i);

            -- Free the memory
            deallocate(effective_message);
            deallocate(timed_message);
            -- Note : The string pointers could be replaced by lines
        end logger_report;

        ---------------------------
        -- Procedure Definitions --
        ---------------------------
        procedure enable_log_to_file(filename : string := "log.txt"; mode : file_open_kind := write_mode)
        is
            variable l : line;
        begin
            if file_status = open_ok then
                report "File is already open";
            else
                file_open(file_status, output_file, filename, mode);
                if file_status /= open_ok then
                    -- Report error with highest severity, but don't increment
                    -- the counters since this is not an error in the DUT.
                    report "File open error !" severity failure;
                else
                    write(l,string'("Simulation with HTML logger"));
                    html_start(output_file, l, "no date");
                end if;
            end if;
        end enable_log_to_file;

        procedure set_verbosity(constant severity_i : severity_level := note) is
        begin
            verbosity_severity := severity_i;
        end set_verbosity;

        procedure log_note(message : string := "") is
        begin
            case verbosity_severity is
                when note =>
                    logger_report(message, note);
                when others =>
            end case;
            nb_notes := nb_notes + 1;
        end log_note;

        procedure log_warning(message : string := "") is
        begin
            case verbosity_severity is
                when note | warning =>
                    logger_report(message, warning);
                when others =>
            end case;
            nb_warnings := nb_warnings + 1;
        end log_warning;

        procedure log_error(message : string := "") is
        begin
            case verbosity_severity is
                when note | warning | error =>
                    logger_report(message, error);
                when others =>
            end case;
            nb_errors := nb_errors + 1;
        end log_error;

        procedure log_failure(message : string := "") is
        begin
            logger_report(message, failure);
        end log_failure;

        procedure final_report is
        begin
            logger_report(CR & "+--------------------+" & CR &
             "| FINAL REPORT       |" & CR & "|--------------------+" & CR &
             "| Nb warnings = " & natural'image(nb_warnings) & CR &
             "| Nb errors   = " & natural'image(nb_errors) & CR & "|" & CR &
             "| Verbosity level is : " &
              severity_level'image(verbosity_severity) & CR & "|" & CR &
              "| END OF SIMULATION");

            if file_status = open_ok then
                html_end(output_file);
            end if;
        end final_report;

    end protected body logger_t;

end logger_pkg;
