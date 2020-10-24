
--- Nguyễn Lê Ngọc Tần
--- 18120553


--===================================================================
--==                   BÀI TẬP THỰC HÀNH 1                         ==
--===================================================================



--======================================= GHI CHÚ ========================================================

-- DO KHÔNG CÓ MIÊU TẢ CỤ THỂ VÀ TỪ KẾT QUẢ RÚT TRÍCH TỪ VIỆC XEM DATABASE NÊN TA XEM:
-- NHÂN VIÊN LÀM VIỆC TRONG 1 TUẦN KỂ CẢ NGÀY CHỦ NHẬT
-- NHÂN VIÊN TRONG 1 PHÒNG BAN CHỈ LÀM 1 CA NHẤT ĐỊNH (8 GIỜ/CA)
-- KHÔNG THAY ĐỔI LƯƠNG QUÁ 2 LẦN TRONG 1 NĂM (Từ bảng dữ liệu EmployeePayHistory ta thấy vậy!)
-- NĂM ĐẦU NHÂN VIÊN MỚI VÀO LÀM CHỈ ĐƯỢC THAY ĐỔI LƯƠNG 1 LẦN (Từ bảng dữ liệu EmployeePayHistory ta thấy vậy!)

--=======================================================================================================




-- 1. Cập nhật lương nhân viên (Thêm 1 dòng dữ liệu vào bảng EmployeePayHistory)
CREATE PROC Update_Luong @BusinessEntityID INT, @RateChangeDate DATETIME, @Rate MONEY, @PayFequency TINYINT
AS
BEGIN
	INSERT INTO EmployeePayHistory
	VALUES (@BusinessEntityID, @RateChangeDate, @Rate, @PayFequency, GETDATE())
END
GO


-- Tigger kiểm tra hợp lệ khi Insert vào bảng EmployeePayHistory
CREATE TRIGGER Insert_Rate ON EmployeePayHistory
FOR INSERT
AS
BEGIN
	DECLARE @ID INT
	DECLARE @R_D DATETIME
	DECLARE @R TINYINT

	SELECT	@ID = EPH_I.BusinessEntityID,
			@R_D = EPH_I.RateChangeDate,
			@R = EPH_I.PayFrequency
	FROM INSERTED EPH_I

	IF (EXISTS (SELECT * FROM EmployeePayHistory EPH
						 WHERE EPH.BusinessEntityID = @ID
						 AND EPH.RateChangeDate > @R_D))
		BEGIN
			PRINT N'RateChangeDate phải là ngày sau ngày cập nhật gần đây nhất'
			ROLLBACK TRAN;
		END

	IF (@R != 1 AND @R != 2)
		BEGIN
			PRINT N'PayFrequency chỉ chứa 2 giá trị: 1 - Trả theo tháng, 2 - Trả theo mỗi 2 tuần'
			ROLLBACK TRAN;
		END
END
GO




-- 2. Tìm kiếm nhân viên theo phòng ban, theo ca làm việc, giới tính
CREATE PROC Find_NV 
	@DepartmentID SMALLINT, @ShiftID TINYINT, @Gender NCHAR(1)
AS
BEGIN
	-- Không truyền vào điều kiện, mặc định select tất cả nhân viên
	IF (@DepartmentID = 0 and @ShiftID = 0 and @Gender is null)
		SELECT * FROM Employee

	-- Kiểm tra giới tính
	IF (@Gender IS NOT NULL AND @Gender != 'F' AND @Gender != 'M')
		BEGIN
			PRINT N'Giới tính không đúng. Giới tính là M hoặc F !'
			RETURN;
		END

	-- Tìm nhân viên theo cả 3 ĐK: phòng ban + ca làm việc + giới tính
	IF (@DepartmentID != 0 AND @ShiftID != 0 AND @Gender IS NOT NULL)
		BEGIN
			SELECT E.*
			FROM Employee E, EmployeeDepartmentHistory EDH
			WHERE E.BusinessEntityID = EDH.BusinessEntityID
			AND EDH.DepartmentID = @DepartmentID -- Đang làm việc tại phòng ban
			AND EDH.EndDate IS NULL
			AND EDH.ShiftID = @ShiftID -- Ca làm việc
			AND E.Gender = @Gender -- Gioi tính

			RETURN;
		END

	-- Tìm nhân viên theo cả 2 ĐK: phòng ban + ca làm việc
	IF (@DepartmentID != 0 AND @ShiftID != 0 AND @Gender IS NULL)
		BEGIN
			SELECT E.*
			FROM Employee E, EmployeeDepartmentHistory EDH
			WHERE E.BusinessEntityID = EDH.BusinessEntityID
			AND EDH.DepartmentID = @DepartmentID -- Đang làm việc tại phòng ban
			AND EDH.EndDate IS NULL
			AND EDH.ShiftID = @ShiftID -- Ca làm việc

			RETURN;
		END

	-- Tìm nhân viên theo cả 2 ĐK: phòng ban +  giới tính
	IF (@DepartmentID != 0 AND @ShiftID = 0 AND @Gender IS NOT NULL)
		BEGIN
			SELECT E.*
			FROM Employee E, EmployeeDepartmentHistory EDH
			WHERE E.BusinessEntityID = EDH.BusinessEntityID
			AND EDH.DepartmentID = @DepartmentID -- Đang làm việc tại phòng ban
			AND EDH.EndDate IS NULL
			AND E.Gender = @Gender -- Gioi tính

			RETURN;
		END

	-- Tìm nhân viên theo cả 2 ĐK:  ca làm việc + giới tính
	IF (@DepartmentID = 0 AND @ShiftID != 0 AND @Gender IS NOT NULL)
		BEGIN
			SELECT E.*
			FROM Employee E, EmployeeDepartmentHistory EDH
			WHERE E.BusinessEntityID = EDH.BusinessEntityID
			AND EDH.EndDate IS NULL
			AND EDH.ShiftID = @ShiftID -- Ca làm việc
			AND E.Gender = @Gender -- Gioi tính

			RETURN;
		END

	-- Tìm nhân viên theo cả 1 ĐK:  phòng ban
	IF (@DepartmentID != 0 AND @ShiftID = 0 AND @Gender IS NULL)
		BEGIN
			SELECT E.*
			FROM Employee E, EmployeeDepartmentHistory EDH
			WHERE E.BusinessEntityID = EDH.BusinessEntityID
			AND EDH.DepartmentID = @DepartmentID -- Đang làm việc tại phòng ban
			AND EDH.EndDate IS NULL

			RETURN;
		END

	-- Tìm nhân viên theo cả 1 ĐK: ca làm việc
	IF (@DepartmentID = 0 AND @ShiftID != 0 AND @Gender IS NULL)
		BEGIN
			SELECT E.*
			FROM Employee E, EmployeeDepartmentHistory EDH
			WHERE E.BusinessEntityID = EDH.BusinessEntityID
			AND EDH.EndDate IS NULL
			AND EDH.ShiftID = @ShiftID -- Ca làm việc

			RETURN;
		END

	-- Tìm nhân viên theo cả 1 ĐK:  giới tính
	IF (@DepartmentID = 0 AND @ShiftID = 0 AND @Gender IS NOT NULL)
		BEGIN
			SELECT E.*
			FROM Employee E, EmployeeDepartmentHistory EDH
			WHERE E.BusinessEntityID = EDH.BusinessEntityID
			AND EDH.EndDate IS NULL
			AND E.Gender = @Gender -- Gioi tính

			RETURN;
		END
END
GO

EXEC Find_NV 1, 1, 'M'










-- 3. Không cho phép xóa nhân viên, khi nhân viên nghỉ việc chỉ cập nhật lại EndDate
CREATE TRIGGER tr_XoaNV on Employee
FOR DELETE
AS
BEGIN
	IF (EXISTS (SELECT E.* FROM Employee E, Deleted D WHERE E.BusinessEntityID = D.BusinessEntityID))
	BEGIN
		PRINT( N'Không được xóa nhân viên, chỉ cập nhật EndDate khi nhân viên nghỉ việc')
		ROLLBACK TRAN;
	END
END 
GO


CREATE PROC Quit_Employee @BusinessEntityID INT
AS
BEGIN
	UPDATE EmployeeDepartmentHistory
	SET EndDate = GETDATE()
	WHERE BusinessEntityID = @BusinessEntityID
	AND EndDate IS NULL
	PRINT N'Đã cập nhật EndDate cho nhân viên có mã ' + cast(@BusinessEntityID AS CHAR(3))
END
GO







-- 4. Nhân viên chỉ làm việc ở 1 phòng ban tại 1 thời điểm
CREATE TRIGGER tr_PhanCong ON EmployeeDepartmentHistory
FOR INSERT
AS
BEGIN
	IF (EXISTS(
				SELECT * 
				FROM EmployeeDepartmentHistory E, INSERTED E_I
				WHERE E.BusinessEntityID = E_I.BusinessEntityID
				AND E.EndDate IS NULL
				AND E.DepartmentID != E_I.DepartmentID
				))
		BEGIN
			PRINT N'Nhân viên hiện vẫn còn làm việc trong 1 phòng ban, nên không thể phân công vào phòng ban khác'
			ROLLBACK ;
		END
END
GO









-- 5. Thống kê lương đã trả cho mỗi nhân viên theo từng năm

-- Tìm năm đầu tiên công ty có nhân viên và phải trả lương cho nhân viên
CREATE FUNCTION Nam_Dau_Co_NV()
RETURNS INT
AS
BEGIN
	DECLARE @Nam INT = 0

	SELECT @Nam = YEAR(E.HireDate)
	FROM Employee E
	WHERE YEAR(E.HireDate) <= ALL
	(
		SELECT YEAR(E1.HireDate)
		FROM Employee E1
	)

	RETURN @Nam
END
GO

-- HÀM Tính lương của một nhân viên theo năm
CREATE FUNCTION Luong_NV_Theo_Nam(@BussinessEntityID int, @Nam int)
RETURNS MONEY
AS 
BEGIN
	DECLARE @Luong MONEY = 0
	DECLARE @NgayThue datetime = -- Ngày thuê nhân viên này
	(
		SELECT E.HireDate FROM Employee E WHERE E.BusinessEntityID = @BussinessEntityID
	)

	IF (@Nam = YEAR(@NgayThue)) 
	-- Tính lương của nhân viên vào năm nhân viên mới vào làm
		BEGIN
			DECLARE @DEM_1 INT = 
			(
				SELECT COUNT(*)
				FROM EmployeePayHistory EPH
				WHERE EPH.BusinessEntityID = @BussinessEntityID
				AND YEAR(EPH.RateChangeDate) = @Nam
			)

			IF (@DEM_1 = 1) 
			-- KHÔNG CÓ THAY ĐỔI LƯƠNG TRONG NĂM ĐẦU LÀM VIỆC
			-- lương cuả nhân viên này trong năm chỉ tính từ ngày được thuê
			-- đến cuối năm đó
				BEGIN
					SELECT @Luong = DATEDIFF(DD, E.HireDate, '12/31/'+ cast(@Nam as char(4))) * 8 * EPH.Rate
					FROM Employee E, EmployeePayHistory EPH
					WHERE E.BusinessEntityID = @BussinessEntityID
					AND  EPH.BusinessEntityID = E.BusinessEntityID
					AND YEAR(EPH.RateChangeDate) = @Nam

					RETURN @Luong
				END
			ELSE 
			-- CÓ 1 LẦN THAY ĐỔI LƯƠNG TRONG NĂM ĐẦU LÀM VIỆC
			-- lương cuả nhân viên này trong năm = 
			--					Lương tính từ ngày được thuê đến ngày cập nhật lương mới
			--				  + Lương tính từ ngày cập nhật lương mới đến cuối năm
				BEGIN 
					DECLARE @LUONG_1a MONEY = 0
					DECLARE @LUONG_2a MONEY = 0

					SELECT @LUONG_1a = DATEDIFF(DD, E.HireDate, EPH2.RateChangeDate) * 8 * EPH1.Rate,
						   @LUONG_2a =  DATEDIFF(DD, EPH2.RateChangeDate, '12/31/' + Cast(@Nam as char(4))) * 8 * EPH2.Rate
					FROM Employee E, EmployeePayHistory EPH1, EmployeePayHistory EPH2
					WHERE E.BusinessEntityID = @BussinessEntityID
					AND EPH1.BusinessEntityID = E.BusinessEntityID
					AND EPH2.BusinessEntityID = E.BusinessEntityID
					AND EPH1.RateChangeDate < EPH2.RateChangeDate
					AND YEAR(EPH1.RateChangeDate) = @Nam
					AND YEAR(EPH2.RateChangeDate) = @Nam

					SET @Luong = @LUONG_1a + @LUONG_2a

					RETURN @Luong
				END
		END


	IF (@Nam > YEAR(@NgayThue) AND @Nam IN (
				SELECT YEAR(EPH.RateChangeDate)
				FROM EmployeePayHistory EPH 
				WHERE EPH.BusinessEntityID = @BussinessEntityID))
	-- Tính lương nhân viên vào năm mà có sự thay đổi lương
		BEGIN
			DECLARE @DEM_2 INT = 
			(
				SELECT COUNT(*)
				FROM EmployeePayHistory EPH
				WHERE EPH.BusinessEntityID = @BussinessEntityID
				AND YEAR(EPH.RateChangeDate) = @Nam
			)
		

			IF (@DEM_2 = 1) 
			-- Thay đổi lương 1 lần trong năm
			-- Thì lương của nhân viên trong năm này = 
			--					Lương trước ngày thay đổi (Từ đầu năm đến ngày thay đổi)
			--				  + Lương sau ngày thay đổi (Từ ngày thay đổi đến cuối năm)
				BEGIN
					DECLARE @LUONG_1b MONEY = 0
					DECLARE @LUONG_2b MONEY = 0

					SELECT @LUONG_1b = DATEDIFF(DD, '1/1/' + Cast(@Nam as char(4)), EPH2.RateChangeDate) * 8 * EPH1.Rate,
						   @LUONG_2b =  DATEDIFF(DD, EPH2.RateChangeDate, '12/31/' + Cast(@Nam as char(4))) * 8 * EPH2.Rate
					FROM Employee E, EmployeePayHistory EPH1, EmployeePayHistory EPH2
					WHERE E.BusinessEntityID = @BussinessEntityID
					AND EPH1.BusinessEntityID = E.BusinessEntityID
					AND EPH2.BusinessEntityID = E.BusinessEntityID
					AND Year(EPH1.RateChangeDate) < @Nam	-- EPH1: Mức lương cũ cập nhật gần đây nhất
					AND Year(EPH1.RateChangeDate) >= ALL
					(
						SELECT YEAR(EPH_.RateChangeDate)
						FROM EmployeePayHistory EPH_
						WHERE EPH_.BusinessEntityID = E.BusinessEntityID
						AND YEAR(EPH_.RateChangeDate) < @Nam
					)
					AND YEAR(EPH2.RateChangeDate) = @Nam	-- EPH2: Mức lương thay đổi trong năm này

					SET @Luong = @LUONG_1b + @LUONG_2b

					RETURN @Luong
				END
			ELSE 
			-- Thay đổi lương 2 lần trong năm
			-- Thì lương của nhân viên trong năm này = 
			--					Lương trước ngày thay đổi lần 1 (Từ đầu năm đến ngày thay đổi lần 1)
			--				  + Lương sau ngày thay đổi lần 1 (Từ ngày thay đổi lần 1 đến ngày thay đổi lần 2)
			--				  + Lương sau ngày thay đổi lần 2 (Từ ngày thay đổi lần 2 đến cuối năm)
				BEGIN
					DECLARE @LUONG_1c MONEY = 0
					DECLARE @LUONG_2c MONEY = 0
					DECLARE @LUONG_3c MONEY = 0

					SELECT @LUONG_1c = DATEDIFF(DD, '1/1/' + Cast(@Nam as char(4)), EPH2.RateChangeDate) * 8 * EPH1.Rate,
						   @LUONG_2c =  DATEDIFF(DD, EPH2.RateChangeDate, EPH3.RateChangeDate) * 8 * EPH2.Rate,
						   @LUONG_3c =  DATEDIFF(DD, EPH3.RateChangeDate, '12/31/' + Cast(@Nam as char(4))) * 8 * EPH3.Rate
					FROM Employee E, EmployeePayHistory EPH1, EmployeePayHistory EPH2, EmployeePayHistory EPH3
					WHERE E.BusinessEntityID = @BussinessEntityID
					AND EPH1.BusinessEntityID = E.BusinessEntityID
					AND EPH2.BusinessEntityID = E.BusinessEntityID
					AND EPH3.BusinessEntityID = E.BusinessEntityID
					AND YEAR(EPH1.RateChangeDate) < @Nam	-- EPH1: Mức lương cũ cập nhật gần đây nhất
					AND Year(EPH1.RateChangeDate) >= ALL
					(
						SELECT YEAR(EPH_.RateChangeDate)
						FROM EmployeePayHistory EPH_
						WHERE EPH_.BusinessEntityID = E.BusinessEntityID
						AND YEAR(EPH_.RateChangeDate) < @Nam
					)
					AND YEAR(EPH2.RateChangeDate) = @Nam -- EPH2: Mức lương cập nhật lần 1 trong năm
					AND YEAR(EPH3.RateChangeDate) = @Nam -- EPH3: Mức lương cập nhật lần 2 trong năm
					AND EPH2.RateChangeDate < EPH3.RateChangeDate

					SET @Luong = @LUONG_1c + @LUONG_2c + @LUONG_3c

					RETURN @Luong
				END
		END
	ELSE
		BEGIN
			-- Tính lương của nhân viên trong các năm còn lại
			-- (Năm đó ko phải năm thuê nhân viên, cũng ko phải năm có thay đổi lương mới)
			SELECT @Luong = EPH.Rate * 8 * DATEDIFF(DD, '1/1/' + CAST(@Nam as char(4)), '12/31/' + CAST(@Nam as char(4)))
			FROM EmployeePayHistory EPH
			WHERE EPH.BusinessEntityID = @BussinessEntityID
			AND YEAR(EPH.RateChangeDate) < @Nam

			RETURN @Luong
		END

	RETURN @Luong
END
GO

-- Hàm tính lương của tất cả nhân viên theo năm
CREATE FUNCTION Luong_Tat_ca_NV_Theo_Nam(@Nam INT)
RETURNS @KQ TABLE
(
	BusinessEntityID INT NOT NULL,
	Luong MONEY
)
AS
BEGIN
	DECLARE C1 CURSOR FOR 
	(
		SELECT E.BusinessEntityID FROM Employee E
		WHERE E.CurrentFlag = 1
		AND YEAR(E.HireDate) <= @Nam
	)
		
	OPEN C1
	DECLARE @ID INT

	FETCH NEXT FROM C1 INTO @ID
	
	WHILE(@@FETCH_STATUS = 0)
	BEGIN
		DECLARE @Luong MONEY = dbo.Luong_NV_Theo_Nam(@ID, @Nam)
		INSERT INTO @KQ VALUES (@ID, @Luong)
		FETCH NEXT FROM C1 INTO @ID
	END

	CLOSE C1
	DEALLOCATE C1

	RETURN
END
GO

CREATE PROC Thong_Ke_Luong_Theo_Nam @Nam INT
AS
BEGIN
	SELECT * FROM dbo.Luong_Tat_ca_NV_Theo_Nam(@Nam)
END
GO

EXEC Thong_Ke_Luong_Theo_Nam 2007







-- 6. Thống kê tổng lương theo từng phòng ban (Lương hiện tại)

-- Tính lương/tháng hiện tại của nhân viên
CREATE FUNCTION Luong_Hien_Tai(@BusinessEntityID INT)
RETURNS MONEY
AS
BEGIN
	DECLARE @L MONEY = 0

	SELECT @L = (EPH.Rate * 8 * 30)
		   -- Lương theo tháng (30 ngày)
	FROM EmployeePayHistory EPH, EmployeeDepartmentHistory EDH
	WHERE EDH.BusinessEntityID = @BusinessEntityID
	AND EDH.EndDate IS NULL	-- Nhân viên hiện đang làm việc tại phòng ban
	AND EPH.RateChangeDate < GETDATE() -- Thời gian cập nhật lương phải < thời gian hiện tại
	AND EPH.RateChangeDate >= ALL
	(
		-- Danh sách lịch sử các mức lương/giờ của nhân viên 
		SELECT EPH1.RateChangeDate
		FROM EmployeePayHistory EPH1
		WHERE EPH1.BusinessEntityID = @BusinessEntityID
	)

	RETURN @L
END
GO

-- Tính tổng lương/tháng của tất cả nhân viên theo phòng ban
CREATE FUNCTION Tong_Luong_Phong_Ban(@DepartmentID TINYINT)
RETURNS MONEY
AS
BEGIN
	DECLARE C3 CURSOR FOR
	(
		SELECT EDH.BusinessEntityID
		FROM EmployeeDepartmentHistory EDH
		WHERE EDH.DepartmentID = @DepartmentID
		AND EDH.EndDate IS NULL
	)
	DECLARE @TongLuong MONEY = 0

	OPEN C3
	DECLARE @B_ID INT

	FETCH NEXT FROM C3 INTO @B_ID

	WHILE(@@FETCH_STATUS = 0)
	BEGIN
		SET @TongLuong = @TongLuong + dbo.Luong_Hien_Tai(@B_ID)
		FETCH NEXT FROM C3 INTO @B_ID
	END

	CLOSE C3
	DEALLOCATE C3

	RETURN @TongLuong
END
GO

CREATE PROC Thong_Ke_Luong_Phong_Ban
AS
BEGIN

	PRINT N'============= THỐNG KÊ TỔNG LƯƠNG/THÁNG HIỆN TẠI THEO PHÒNG BAN ============='
	PRINT ' '
	PRINT N'Mã phòng   ||        Tên Phòng              ||    Tổng lương'
	DECLARE C2 CURSOR FOR
	(
		SELECT D.DepartmentID, D.Name
		FROM Department D
	)

	OPEN C2
	DECLARE @ID INT
	DECLARE @Name NVARCHAR(50)

	FETCH NEXT FROM C2 INTO @ID, @Name

	WHILE(@@FETCH_STATUS = 0)
	BEGIN
		PRINT CAST(@ID AS CHAR(11)) + '||  ' + CAST(@Name as NCHAR(29)) + '||    ' + 	
				CAST( dbo.Tong_Luong_Phong_Ban(@ID) AS CHAR(30))

		FETCH NEXT FROM C2 INTO @ID, @Name
	END

	CLOSE C2
	DEALLOCATE C2
END
GO

EXEC Thong_Ke_Luong_Phong_Ban