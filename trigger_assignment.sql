use hr;

-- How can MySQL triggers be used to automatically update employee records when a department is changed?
delimiter $$ 
create trigger trg_before_update 
before update on departments
for each row 
begin 
     if  old.department_name <> new.department_name then 
         update employees 
         set department_name = new.department_name 
         where department_id = new.department_id ;
     end if;
end;
 $$
delimiter ;






-- What MySQL trigger can be used to prevent an employee from being deleted if they are currently assigned to a department?

delimiter  //
create trigger prevent_employee_deletion
before delete on employees
for each row
begin
    if old.dept_id is not null then 
        signal sqlstate '45000'
        set message_text = 'Cannot delete employee: still assigned to a department.';
    end if ;
end ;
//

delimiter ;



-- How can a MySQL trigger be used to send an email notification to HR when an employee is hired or terminated?
CREATE TABLE hr_notifications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    employee_id DECIMAL(6,0),
    action_type VARCHAR(20),         -- 'Hired' or 'Terminated'
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    processed BOOLEAN DEFAULT FALSE
);

delimiter //
create trigger email_noti
after insert on employees
for each row 
begin 
     insert into hr_notifications (employee_id, action_type)
      values (new.EMPLOYEE_ID, 'Hired');
end ;
//
delimiter ;
-- terminations
DELIMITER $$
create trigger trg_employee_terminated
after delete on employees
for each row
begin
    insert into hr_notifications (employee_id, action_type)
    values (old.EMPLOYEE_ID, 'Terminated');
end$$
DELIMITER ;



-- What MySQL trigger can be used to automatically assign a new employee to a department based on their job title?

DELIMITER //

CREATE TRIGGER assign_department_on_hire
BEFORE INSERT ON employees
FOR EACH ROW
BEGIN
    DECLARE dept INT;
    -- Look up department based on job title
    SELECT department_id INTO dept
    FROM jobs
    WHERE job_title = NEW.job_title;
    
    -- Assign department if found
    IF dept IS NOT NULL THEN
        SET NEW.department_id = dept;
    ELSE
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No department mapping found for this job title.';
    END IF;
END;
//
DELIMITER ;
-- How can a MySQL trigger be used to calculate and update the total salary budget
--  for a department whenever a new employee is hired or their salary is changed?
DELIMITER $$
create trigger trg_after_employee_insert
after insert on employees
for each row 
begin
    -- If department already exists, update budget
    if exists(
        select 1 from employees where department_id = new.DEPARTMENT_ID
    ) then
        UPDATE employees set salary = salary + new.SALARY
        WHERE department_id = new.DEPARTMENT_ID;
    else
        insert into employees (department_id, salary)
        values (new.DEPARTMENT_ID, new.SALARY);
    end if ;
end$$
DELIMITER ;


-- What MySQL trigger can be used to enforce a maximum number of employees that can be assigned to a department?

DELIMITER $$
create trigger  trg_limit_department_size
before insert on  employees
for each row
begin
    declare emp_count int;

    select COUNT(*) into emp_count
    from employees
    where DEPARTMENT_ID = new.DEPARTMENT_ID;

    if emp_count >= 10 then
        signal sqlstate '45000'
       set message_text = 'Department has reached the maximum number of employees.';
    end if;
end$$
DELIMITER ;

-- How can a MySQL trigger be used to update the department manager whenever an employee 
-- under their supervision is promoted or leaves the company?

alter table  employees add column last_team_change datetime;
DELIMITER $$
-- Trigger for Promotion (AFTER UPDATE)
create trigger trg_employee_promoted
after update on employees
for each row
begin 
    if old.JOB_ID <> new.JOB_ID or old.SALARY <> new.SALARY then
        update employees
        set last_team_change = NOW()
        where EMPLOYEE_ID = new.MANAGER_ID;
    end if;
end $$
DELIMITER ;
-- Trigger for Termination (AFTER DELETE)
DELIMITER $$
create trigger trg_employee_terminated
after delete on employees
for each row
begin
    update employees
    set last_team_change = NOW()
    where EMPLOYEE_ID = old.MANAGER_ID;
end$$
DELIMITER ;



-- What MySQL trigger can be used to automatically archive the records of an employee who has been terminated or has left the company?

alter table employees add column terminated_on datetime default current_timestamp

DELIMITER $$
create trigger trg_archive_employee
after delete on employees
for each row
begin
    insert into employees_archive (
        EMPLOYEE_ID, FIRST_NAME, LAST_NAME, EMAIL, PHONE_NUMBER,
        HIRE_DATE, JOB_ID, SALARY, COMMISSION_PCT,
        MANAGER_ID, DEPARTMENT_ID
    )
    values (
        old.EMPLOYEE_ID, old.FIRST_NAME, old.LAST_NAME, old.EMAIL, old.PHONE_NUMBER,
        old.HIRE_DATE, old.JOB_ID, old.SALARY, old.COMMISSION_PCT,
        old.MANAGER_ID, old.DEPARTMENT_ID
    );
end$$

DELIMITER ;
