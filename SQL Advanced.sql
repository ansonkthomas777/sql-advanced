use testing

/*-- 1. Create a trigger for EmpDemo table so that 
when a record is inserted/updated and deleted it get inserted into the EmpDemo_Log table*/
GO
Create Table EmpDemo
(
EmpNo int identity Primary Key,
Ename Varchar(55),
Salary Money,
DeptNo int
)
GO

Create Table EmpDemo_Log
(
EmpNo int ,
Ename Varchar(55),
Salary Money,
DeptNo int,
[Action] varchar(15),
DateCreated DateTime
)
GO
 INSERT INTO EmpDemo VALUES('censon',20000,24)

 GO
CREATE TRIGGER EmpDemo_Trigger
on EmpDemo

AFTER INSERT,UPDATE,DELETE
AS 

BEGIN
        
       
	   
       DECLARE @EmpNo INT,@Ename VARCHAR,@Salary MONEY,@DeptNo INT
	   
	   /*.......INSERT.......*/

	   IF EXISTS(SELECT * FROM INSERTED)AND NOT EXISTS(SELECT * FROM DELETED)

       BEGIN
       SELECT @EmpNo = INSERTED.EmpNo,@Ename=INSERTED.Ename,@Salary=INSERTED.Salary,@DeptNo=INSERTED.DeptNo     
       FROM INSERTED
 
       INSERT INTO EmpDemo_Log
       VALUES(@EmpNo,@Ename,@Salary,@DeptNo,'Inserted',GETDATE())
	   END

	   /*-----------UPDATE--------------*/

	     IF EXISTS(SELECT * FROM INSERTED)AND EXISTS(SELECT * FROM DELETED)
		 BEGIN
       SELECT @EmpNo = INSERTED.EmpNo,@Ename=INSERTED.Ename,@Salary=INSERTED.Salary,@DeptNo=INSERTED.DeptNo     
       FROM INSERTED
 
       INSERT INTO EmpDemo_Log
       VALUES(@EmpNo,@Ename,@Salary,@DeptNo, 'Updated',GETDATE())
	   END

	   /*.....DELETED................*/
	    IF NOT EXISTS(SELECT * FROM INSERTED)AND EXISTS(SELECT * FROM DELETED)
		 BEGIN
       SELECT @EmpNo = INSERTED.EmpNo,@Ename=INSERTED.Ename,@Salary=INSERTED.Salary,@DeptNo=INSERTED.DeptNo     
       FROM INSERTED
 
       INSERT INTO EmpDemo_Log
       VALUES(@EmpNo,@Ename,@Salary,@DeptNo, 'Deleted',GETDATE())
	   END
END

GO
/*.............2. Write a procedure to get employee data based on DeptNo.
 If value for DeptNo  is not given get all employees (Using Optional parameter)
  (use transaction and error handling)............*/    

  
CREATE PROCEDURE EMPLOYEE_BASED_DEPARTMENT 
(
 @DeptNo int=null
 )
AS

BEGIN TRY
      BEGIN TRANSACTION
	       IF @DeptNo is null
               (SELECT * FROM EmpDemo)
	  
	      ELSE
	           (SELECT EmpNo,Ename,Salary FROM EmpDemo
	           WHERE DeptNo=@DeptNo)
      COMMIT TRANSACTION
END TRY

BEGIN CATCH
ROLLBACK TRANSACTION
 END CATCH
            

GO

EXEC EMPLOYEE_BASED_DEPARTMENT 22
GO

DROP PROCEDURE EMPLOYEE_BASED_DEPARTMENT
GO
/*....3. Write a procedure to insert data into EmpDemo table and get
 new EmpNo generated as Output parameter(use transaction and error handling)...........*/
 
 CREATE PROCEDURE INSERT_DATA_EMPDEMO
 (
 @Ename varchar(55),
 @Salary money,
 @DeptNo int,
 @Output int out)
 AS
 BEGIN TRY
      BEGIN TRANSACTION
	       INSERT INTO EmpDemo VALUES(@Ename,@Salary,@DeptNo)
		  set @Output =(select SCOPE_IDENTITY())
		  PRINT @Output
      COMMIT TRANSACTION
END TRY

BEGIN CATCH
ROLLBACK TRANSACTION
 END CATCH    
            


DROP PROCEDURE INSERT_DATA_EMPDEMO
GO
DECLARE @Output int
EXEC INSERT_DATA_EMPDEMO 'Febin',30000,25,@Output out

 /*.......4. Write a user defined function to get total salary of given
  department Write a user defined function to get department and total salary..........*/
  GO
  CREATE FUNCTION dbo.EmpDemoFunction(@DeptNo int)  
RETURNS int  
AS    
BEGIN  
    DECLARE @ret int;  
    SELECT @ret = SUM(EmpDemo.Salary)   
    FROM EmpDemo  
    WHERE EmpDemo.DeptNo=@DeptNo         
     IF (@ret IS NULL)   
        SET @ret = 0;  
    RETURN @ret;  

END;  

GO
select dbo.EmpDemoFunction(22) as TotalSalary

GO  
drop function dbo.EmpDemoFunction;

GO
/*.......................*/

CREATE FUNCTION dbo.TotSalBaseDept()
RETURNS @table table(DeptNo int null,Salary money null)
AS
BEGIN
INSERT @table
SELECT DeptNo as DepartmentNumber,sum(Salary) as TotalSalary
FROM EmpDemo
GROUP BY DeptNo
RETURN
END
select * from dbo.TotSalBaseDept()
drop function dbo.TotSalBaseDept

/*...........5. Write a Cursor to concatenate all ename from EmpDemo table to a string.........*/

/*DECLARE @MaxCount INTEGER
DECLARE @Count INTEGER

SET @Count = 1*/
DECLARE @Ename VARCHAR(MAX)
DECLARE @Txt VARCHAR(MAX)=''
DECLARE @MyCursor CURSOR

SET @MyCursor=CURSOR FAST_FORWARD
 FOR  
 SELECT Ename FROM EmpDemo
 OPEN @MyCursor
 FETCH NEXT  FROM @MyCursor
 INTO @Ename
 WHILE @@FETCH_STATUS=0
 BEGIN
 SET @Txt=@Txt+@Ename
 FETCH NEXT  FROM @MyCursor
 INTO @Ename 
 END
  PRINT @Txt
  
 
CLOSE @MyCursor   
DEALLOCATE @MyCursor

/*......6. Create a view for EmpDemo table and try to Insert records into the view...........*/

GO

CREATE VIEW ViewForEmpDemo AS SELECT * FROM EmpDemo
SELECT * FROM ViewForEmpDemo
INSERT INTO ViewForEmpDemo VALUES('DennisjOSEPH',4000,23)

GO
/*............7. Using CTE return the First Name, Last Name 
           and Current Salary of the entire employee’s...........*/
		   DECLARE @delimiter VARCHAR(50)
           SET @delimiter=' ';
		   WITH RETURNCTE
		   AS
		   (
		   
		   SELECT
        EmpNo,         
        CAST('<M>' + REPLACE([Ename], @delimiter , '</M><M>') + '</M>' AS XML) 
        AS [Ename XML],Salary
    FROM  EmpDemo		   
		   )
		   select EmpNo, [Ename XML].value('/M[1]', 'varchar(50)') As [First Name],
     [Ename XML].value('/M[2]', 'varchar(50)') As [Last Name],Salary from RETURNCTE

/*...............8. List the Employee Name(Last Name, First Name),Address, Designation, 
Country name, state name, city name, Join Date, Current Salary using the following:
a. Table Variable
b. Temp Table....................*/


/*........Temp Table..........*/
CREATE TABLE #EmployeeTemporaryTable
(Id INT, FirstName VARCHAR(50),LastName VARCHAR(50),Address VARCHAR(50),
Designation VARCHAR(50),CountryName VARCHAR(50),StateName VARCHAR(50),
CityName VARCHAR(50),JoinDate datetime,CurrentSalary money )
INSERT INTO #EmployeeTemporaryTable
VALUES(1,'Anson','Thomas','New Jersey','Software Engineer','USA','New Jersey','New Jersey','11/2/2012',10000) 
SELECT * FROM #EmployeeTemporaryTable
DROP TABLE #EmployeeTemporaryTable

GO
 /*........Table Variable..........*/

 DECLARE @EmployeeTableVariable TABLE
(
 Id INT, FirstName VARCHAR(50),LastName VARCHAR(50),Address VARCHAR(50),
Designation VARCHAR(50),CountryName VARCHAR(50),StateName VARCHAR(50),
CityName VARCHAR(50),JoinDate datetime,CurrentSalary money  
)
INSERT INTO @EmployeeTableVariable
VALUES(1,'Anson','Thomas','New Jersey','Software Engineer','USA','New Jersey','New Jersey','11/2/2012',10000) 
SELECT * FROM @EmployeeTableVariable
GO


