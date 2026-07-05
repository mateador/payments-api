
-- Creating the procedure
CREATE OR REPLACE PROCEDURE get_date (
    name_in IN VARCHAR2,
    date_out OUT VARCHAR2)
IS
BEGIN
SELECT to_char(CURRENT_TIMESTAMP, 'YYYY-MM-DD') INTO date_out FROM dual;
END get_date;

-- Executing the procedure
DECLARE
date_out VARCHAR2(200);
BEGIN
    get_date('', date_out);
    dbms_output.put_line(date_out);
END;
/



CREATE OR REPLACE PROCEDURE get_date (name_in IN VARCHAR2, date_out OUT VARCHAR2) IS BEGIN SELECT to_char(CURRENT_TIMESTAMP, 'YYYY-MM-DD') INTO date_out FROM dual; END get_date;