SELECT * FROM books;
SELECT * FROM branch;
SELECT * FROM employees;
SELECT * FROM issued_status;
SELECT * FROM members;
SELECT * FROM return_status;

--Project Tasks


--Task 1: Create a New Book Record -- "978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')"
INSERT INTO books (isbn, book_title, category, rental_price, status, author, publisher)
VALUES
('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');
SELECT * FROM books;

--Task 2: Update an Existing Member's Address
UPDATE members
SET member_address = '125 Main St'
WHERE member_id = 'C101';
SELECT * FROM members;

--Task 3: Delete a Record from the Issued Status Table -- Objective: Delete the record with issued_id = 'IS121' from the issued_status table.
DELETE FROM issued_status
WHERE issued_id = 'IS121'
SELECT * FROM issued_status;

--Task 4: Retrieve All Books Issued by a Specific Employee -- Objective: Select all books issued by the employee with emp_id = 'E101'.
SELECT * 
FROM issued_status
WHERE issued_emp_id = 'E101'

--Task 5: List Members Who Have Issued More Than One Book -- Objective: Use GROUP BY to find members who have issued more than one book.
SELECT 
issued_emp_id,
COUNT (issued_id) AS issued_books
FROM issued_status
GROUP BY 1
HAVING COUNT(issued_id) > 1
ORDER BY 2 DESC 


--CTAS
--Task 6: Create Summary Tables: Use CTAS to generate new tables based on query results - each book and total book_issued_cnt**

CREATE TABLE book_cnts
AS
SELECT 
b.isbn,
b.book_title,
COUNT(ist.issued_id) as no_issued
FROM books as b
JOIN 
issued_status as ist
ON ist.issued_book_isbn = b.isbn
GROUP BY 1,2

SELECT * FROM
book_cnts


--Data Analysis

--Task 7. Retrieve All Books in a Specific Category:

SELECT * FROM books
WHERE category = 'Classic'

--Task 8: Find Total Rental Income by Category:
SELECT 
	b.category,
	SUM(b.rental_price) AS total_income
FROM books as b
JOIN 
issued_status as ist
ON ist.issued_book_isbn = b.isbn
GROUP BY 1
ORDER BY total_income DESC

--Task 9: List Members Who Registered in the Last 180 Days:
SELECT * 
FROM members
WHERE reg_date >= CURRENT_DATE - INTERVAL '180 days';

INSERT INTO members (member_id, member_name, member_address, reg_date)
VALUES
('C120', 'Albert Einstein', '234 Bakery St', '2025-05-02'),
('C121', 'Lebron the Goat', '923 Cookery St', '2025-04-28')

--Task 10: List Employees with Their Branch Manager's Name and their branch details:

SELECT 
    e1.emp_id,
    e1.emp_name,
    e1.position,
    e1.salary,
    b.*,
    e2.emp_name as manager
FROM employees as e1
JOIN 
branch as b
ON e1.branch_id = b.branch_id    
JOIN
employees as e2
ON e2.emp_id = b.manager_id

--Task 11. Create a Table of Books with Rental Price Above a Certain Threshold:
CREATE TABLE books_price_greater_than_six
AS
SELECT * 
FROM books
WHERE rental_price >= 6;

SELECT * FROM books_price_greater_than_six

--Task 12: Retrieve the List of Books Not Yet Returned
SELECT*
FROM issued_status as ist
LEFT JOIN
return_status as ret
ON ret.issued_id = ist.issued_id
WHERE ret.return_date IS NULL


-- Advanced SQL operations

/*Task 13: Identify Members with Overdue Books
Write a query to identify members who have overdue books (assume a 30-day return period). Display the member's_id, member's name, book title, issue date, and days overdue.
*/

SELECT 
	ist.issued_member_id,
	m.member_name,
	bk.book_title,
	ist.issued_date,
	CURRENT_DATE - ist.issued_date AS overdue_days
FROM issued_status AS ist
JOIN members AS m
	ON m.member_id = ist.issued_member_id
JOIN books AS bk
	ON bk.isbn = ist.issued_book_isbn
LEFT JOIN return_status AS rs
	ON rs.issued_id = ist.issued_id
WHERE rs.return_date is NULL
	AND
	CURRENT_DATE - ist.issued_date > 30
ORDER BY 1


/*Task 14: Update Book Status on Return
Write a query to update the status of books in the books table to "Yes" when they are returned (based on entries in the return_status table)
*/

SELECT *
FROM books
WHERE isbn = '978-0-451-52994-2'


SELECT *
FROM issued_status
WHERE issued_book_isbn = '978-0-451-52994-2'

UPDATE books
SET status = 'no'
WHERE isbn = '978-0-451-52994-2'

SELECT *
FROM return_status
WHERE issued_id = 'IS130' --not returned


--Store procedures - Solve for task 14 (SYNTAX)
CREATE OR REPLACE PROCEDURE add_return_records(p_return_id VARCHAR(10), p_issued_id VARCHAR(10), p_book_quality VARCHAR(10))
LANGUAGE plpgsql
AS $$

DECLARE
    v_isbn VARCHAR(20);
    v_book_name VARCHAR(75);
    
BEGIN
    -- all your logic and code
    -- inserting into returns based on users input
    INSERT INTO return_status(return_id, issued_id, return_date, book_quality)
    VALUES
    (p_return_id, p_issued_id, CURRENT_DATE, p_book_quality);

    SELECT 
        issued_book_isbn,
        issued_book_name
        INTO
        v_isbn,
        v_book_name
    FROM issued_status
    WHERE issued_id = p_issued_id;

    UPDATE books
    SET status = 'yes'
    WHERE isbn = v_isbn;

    RAISE NOTICE 'Thank you for returning the book: %', v_book_name;
    
END;
$$

CALL add_return_records('RS138', 'IS135', 'Good');


/*Task 15: Branch Performance Report
Create a query that generates a performance report for each branch, showing the number of books issued, the number of books returned, and the total revenue generated from book rentals.
*/
--branch -> employees -> issued_status -> books table for price -> return table to count the total books returned 
--then display count of books issued
--count of books returned
-- total revenue from book rentals

CREATE TABLE branch_report
AS
SELECT 
	br.branch_id,
	br.manager_id,
	COUNT(ist.issued_id) AS number_book_issued,
	COUNT(rs.return_id) AS number_book_returned,
	SUM(bk.rental_price) AS total_revenue
FROM issued_status AS ist
JOIN employees AS emp
ON emp.emp_id = ist.issued_emp_id
JOIN branch AS br
ON br.branch_id = emp.branch_id
LEFT JOIN return_status AS rs
ON rs.issued_id = ist.issued_id
JOIN books AS bk
ON bk.isbn = ist.issued_book_isbn
GROUP BY 1,2; 

SELECT *
FROM branch_report


/*Task 16: CTAS: Create a Table of Active Members
Use the CREATE TABLE AS (CTAS) statement to create a new table active_members containing members who have issued at least one book in the last 2 months.*/


CREATE TABLE active_members
AS
SELECT * FROM members
WHERE member_id IN (SELECT 
                        DISTINCT issued_member_id   
                    FROM issued_status
                    WHERE 
                        issued_date >= CURRENT_DATE - INTERVAL '2 month'
                    )
;

SELECT * FROM active_members;


/*Task 17: Find Employees with the Most Book Issues Processed
Write a query to find the top 3 employees who have processed the most book issues. Display the employee name, number of books processed, and their branch.*/

SELECT 
br.branch_id,
emp.emp_name,
COUNT(ist.issued_id) AS books_processed
FROM issued_status AS ist
JOIN employees AS emp
ON emp.emp_id = ist.issued_emp_id
JOIN branch as br
ON emp.branch_id = br.branch_id
GROUP BY 1,2
ORDER BY 3 DESC
LIMIT 3


