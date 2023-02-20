-------------------------------------------------------------------------------
--    Copyright 2018 HES-SO HEIG-VD REDS
--    All Rights Reserved Worldwide
--
--    Licensed under the Apache License, Version 2.0 (the "License");
--    you may not use this file except in compliance with the License.
--    You may obtain a copy of the License at
--
--        http://www.apache.org/licenses/LICENSE-2.0
--
--    Unless required by applicable law or agreed to in writing, software
--    distributed under the License is distributed on an "AS IS" BASIS,
--    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--    See the License for the specific language governing permissions and
--    limitations under the License.
-------------------------------------------------------------------------------
--
-- File        : html_report_pkg.vhd
-- Description : This package offers a simple way to generate an HTML report
--               for a VHDL simulation. The generated file allows to view
--               messages in a browser and to choose what severity level to
--               display.
--
-- Author      : Yann Thoma
-- Team        : REDS institute
-- Date        : 07.03.18
--
--
--| Modifications |------------------------------------------------------------
-- Ver  Date      Who   Description
-- 1.0  07.03.18  YTA   First version
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;

package html_report_pkg is

    -- Adds a message with a certain severity level. The input message is of
    -- type Line
    procedure html_write(file f: text;
                         l:inout line;
                         sev:severity_level);

    -- Adds a message with a certain severity level. The input message is of
    -- type string
    procedure html_report(file f: text;
                          message : in string;
                          sev:severity_level);

    -- This procedure has to be called at the beginning, in order to ensure
    -- correct HTML tags
    procedure html_start(file f: text;
                         l:inout line;
                         date: in string);

    -- This procedure has to be called at the end of the simulation, in order
    -- to ensure correct ending of HTML tags
    procedure html_end(file f:text);

end html_report_pkg;


package body html_report_pkg is

    procedure html_report(file f: text;message : in string;sev:severity_level) is
        variable tmp_line : line;
    begin
        write(tmp_line,message);
        html_write(f,tmp_line,sev);
    end html_report;

    procedure html_write(file f: text;l:inout line;sev:severity_level) is
        variable tmp_line: line;
    begin
        case sev is
        when NOTE =>
            write(tmp_line,string'("<tr class='note'><td>Note</td><td>"));
            write(tmp_line,now);
            write(tmp_line,string'("</td><td>"));
        when WARNING =>
            write(tmp_line,string'("<tr class='warning'><td>Warning</td><td>"));
            write(tmp_line,now);
            write(tmp_line,string'("</td><td>"));

        when ERROR =>
            write(tmp_line,string'("<tr class='error'><td>Error</td><td>"));
            write(tmp_line,now);
            write(tmp_line,string'("</td><td>"));

        when FAILURE =>
            write(tmp_line,string'("<tr class='failure'><td>Failure</td><td>"));
            write(tmp_line,now);
            write(tmp_line,string'("</td><td>"));

        end case;
        writeline(f,tmp_line);
        writeline(f,l);
        write(l,string'("</td></tr>"));
        writeline(f,l);

    end html_write;

    procedure html_start(file f: text;l:inout line;date: in string) is
        variable tmp_line: line;
    begin
        write(tmp_line,string'("<html><head>" & CR));

        write(tmp_line,string'("<script type=""text/javascript"">" & CR));
        write(tmp_line,string'("function toggle(theid){" & CR));
        write(tmp_line,string'("  var elements = document.getElementsByClassName(theid);" & CR));
        write(tmp_line,string'("  for (var i in elements) {" & CR));
        write(tmp_line,string'("    if (elements.hasOwnProperty(i)) {" & CR));
        write(tmp_line,string'("      if (elements[i].style.display=='none')" & CR));
        write(tmp_line,string'("        elements[i].style.display='';" & CR));
        write(tmp_line,string'("      else" & CR));
        write(tmp_line,string'("        elements[i].style.display = 'none';" & CR));
        write(tmp_line,string'("    }" & CR));
        write(tmp_line,string'("  }" & CR));
        write(tmp_line,string'("}" & CR));
        write(tmp_line,string'("</script>" & CR));


        write(tmp_line,string'("<style type=""text/css"">" & CR));
        write(tmp_line,string'("<!--" & CR));
        write(tmp_line,string'("body { margin: 0; padding: 0;}" & CR));
        write(tmp_line,string'(".note {background-color: rgb(240,240,240);font-size: 12px;font-family: Arial;padding: 3px;margin:3px;}" & CR));
        write(tmp_line,string'(".warning {background-color: rgb(200,200,200);font-size: 12px;font-family: Arial}" & CR));
        write(tmp_line,string'(".error {background-color: rgb(255,160,160);font-size: 12px;font-family: Arial}" & CR));
        write(tmp_line,string'(".failure {background-color: rgb(255,80,80);font-size: 12px;font-family: Arial}" & CR));
        write(tmp_line,string'("-->" & CR));
        write(tmp_line,string'("</style>" & CR));

        write(tmp_line,string'("</head>" & CR));

        write(tmp_line,string'("<body>" & CR));
        write(tmp_line,string'("<h1>"));
        writeline(f,tmp_line);
        writeline(f,l);
        write(tmp_line,string'("</h1>" & CR));
        write(tmp_line,string'("<p>Date: " & CR));
        write(tmp_line,date);
        write(tmp_line,string'("</p>" & CR));
        write(tmp_line,string'("Show/Hide : "));
        write(tmp_line,string'("<input id=""note_button"" type=""button"" value=""Note"" name=""showNote"" onclick=""toggle('note')""; >" & CR));

        write(tmp_line,string'("<input id=""warning_button"" type=""button"" value=""Warning"" name=""showWarning"" onclick=""toggle('warning')""; >" & CR));
        write(tmp_line,string'("<input id=""error_button"" type=""button"" value=""Error"" name=""showError"" onclick=""toggle('error')""; >" & CR));
        write(tmp_line,string'("<input id=""failure_button"" type=""button"" value=""Failure"" name=""showFailure"" onclick=""toggle('failure')""; >" & CR));



        write(tmp_line,string'("<center>"));
        write(tmp_line,string'("<table cellpadding=""7"">"));
        write(tmp_line,string'("<tr><td>Type</td><td>Time</td><td>Description</td></tr>"));
        writeline(f,tmp_line);
    end html_start;

    procedure html_end(file f:text) is
        variable tmp_line: line;
    begin
        write(tmp_line,string'("</table></center></body></html>"));
        writeline(f,tmp_line);
    end html_end;

end html_report_pkg;
