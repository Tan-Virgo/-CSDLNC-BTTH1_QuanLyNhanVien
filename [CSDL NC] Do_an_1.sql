-- 18120553
-- Nguyễn Lê Ngọc Tần


--======================================= ĐỒ ÁN 1 ========================================================

-- GHI CHÚ:
-- DO KHÔNG CÓ MIÊU TẢ CỤ THỂ VÀ TỪ KẾT QUẢ RÚT TRÍCH TỪ VIỆC XEM DATABASE NÊN TA XEM:
-- NHÂN VIÊN LÀM VIỆC TRONG 1 TUẦN KỂ CẢ NGÀY CHỦ NHẬT
-- NHÂN VIÊN TRONG 1 PHÒNG BAN CHỈ LÀM 1 CA NHẤT ĐỊNH (8 GIỜ/CA)
-- KHÔNG THAY ĐỔI LƯƠNG QUÁ 2 LẦN TRONG 1 NĂM (Từ bảng dữ liệu EmployeePayHistory ta thấy vậy!)
-- NĂM ĐẦU NHÂN VIÊN MỚI VÀO LÀM CHỈ ĐƯỢC THAY ĐỔI LƯƠNG 1 LẦN (Từ bảng dữ liệu EmployeePayHistory ta thấy vậy!)

--=======================================================================================================


-- a) Danh sách lương hiện tại của nhân viên
CREATE VIEW LuongNV
AS
SELECT E.BusinessEntityID, EDH.DepartmentID, -- Phòng ban đang làm việc
	   (EPH.Rate * 8 * 30) AS 'Luong'
	   -- Lương theo tháng (30 ngày)
FROM Employee E, EmployeePayHistory EPH, EmployeeDepartmentHistory EDH
WHERE E.BusinessEntityID = EPH.BusinessEntityID
AND E.BusinessEntityID = EDH.BusinessEntityID
AND EDH.EndDate IS NULL	-- Nhân viên hiện đang làm việc tại phòng ban
AND EPH.RateChangeDate < GETDATE() -- Thời gian cập nhật lương phải < thời gian hiện tại
AND EPH.RateChangeDate >= ALL
(
	-- Danh sách lịch sử các mức lương/giờ của nhân viên 
	SELECT EPH1.RateChangeDate
	FROM EmployeePayHistory EPH1
	WHERE EPH1.BusinessEntityID = E.BusinessEntityID
)



-- b) Tổng lương trả cho nhân viên theo từng năm
-- Tính tổng lương mà công ty trả cho nhân viên theo năm
-- (từ năm có nhân viên đầu tiên đến năm nay)
DECLARE @Luong_Nam TABLE
(
	Nam INT NOT NULL,
	Luong FLOAT NOT NULL
)

DECLARE @Nam INT = dbo. Nam_Dau_Co_NV()
WHILE(@Nam < YEAR(GETDATE()))
	BEGIN
		DECLARE @S FLOAT = dbo.Tong_Luong_Theo_Nam(@Nam)
		INSERT INTO @Luong_Nam
		VALUES (@Nam, @S)
		SET @Nam = @Nam + 1
	END

SELECT * FROM  @Luong_Nam


-- Tính tổng lương theo năm mà công ty phải chi trả
alter FUNCTION Tong_Luong_Theo_Nam(@Nam INT)
RETURNS FLOAT
AS
BEGIN
	DECLARE @TONG_LUONG FLOAT = 0

	DECLARE C1 CURSOR FOR 
		SELECT E.BusinessEntityID
		FROM Employee E
		WHERE YEAR(E.HireDate) <= @Nam
		AND E.CurrentFlag = 1 -- Còn làm việc cho công ty

	OPEN C1
	DECLARE @ID INT

	FETCH NEXT FROM C1 INTO @ID
	WHILE(@@FETCH_STATUS = 0)
	BEGIN
		SET @TONG_LUONG = @TONG_LUONG + dbo.Luong_NV_Theo_Nam(@ID, @Nam)
		FETCH NEXT FROM C1 INTO @ID
	END

	CLOSE C1
	DEALLOCATE C1

	RETURN @TONG_LUONG
END
GO

-- Tìm năm đầu tiên công ty có nhân viên và phải trả lương cho nhân viên
alter FUNCTION Nam_Dau_Co_NV()
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

-- Tính lương của nhân viên theo năm
alter FUNCTION Luong_NV_Theo_Nam(@BussinessEntityID int, @Nam int)
RETURNS FLOAT
AS 
BEGIN
	DECLARE @Luong FLOAT = 0
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
					DECLARE @LUONG_1a FLOAT = 0
					DECLARE @LUONG_2a FLOAT = 0

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
					DECLARE @LUONG_1b FLOAT = 0
					DECLARE @LUONG_2b FLOAT = 0

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
					DECLARE @LUONG_1c FLOAT = 0
					DECLARE @LUONG_2c FLOAT = 0
					DECLARE @LUONG_3c FLOAT = 0

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




-- c) Danh sách nhân viên có lương cao nhất từng phòng ban
SELECT D.DepartmentID, D.Name, L.BusinessEntityID, L.Luong
FROM LuongNV L, EmployeeDepartmentHistory EDH, Department D
WHERE L.BusinessEntityID = EDH.BusinessEntityID
AND EDH.DepartmentID = D.DepartmentID
AND EDH.EndDate IS NULL -- Nhân viên còn làm việc trong phòng ban
AND NOT EXISTS 
(
	-- Không tồn tại
	-- Nhân viên thuộc phòng ban trên mà có lương cao hơn
	SELECT *
	FROM LuongNV L1, EmployeeDepartmentHistory EDH1
	WHERE L1.BusinessEntityID = EDH1.BusinessEntityID
	AND EDH1.EndDate IS NULL
	AND EDH1.DepartmentID = D.DepartmentID
	AND L1.Luong > L.Luong
)
ORDER BY D.DepartmentID


-- d) Danh sách nhân viên hiện đang thuộc phòng Production đã vào làm
-- từ 5 năm trở lên
SELECT E.*
FROM Employee E, EmployeeDepartmentHistory EDH, Department D
WHERE E.BusinessEntityID = EDH.BusinessEntityID
AND EDH.DepartmentID = D.DepartmentID
AND D.Name = 'Production'
AND DATEDIFF(DD, E.HireDate, GETDATE())/365 >= 5 -- Năm làm việc tính từ ngày được thuê vào làm
AND EDH.EndDate IS NULL -- Vẫn đang làm phòng 'Production'
AND E.CurrentFlag = 1


-- e) Danh sách nhân viên còn làm việc tại công ty
SELECT E.*
FROM Employee E
WHERE E.CurrentFlag = 1


-- f) Lịch sử công tác và mức lương cao nhất tương ứng tại vị trí công tác 
-- của nhân viên có id = 4
SELECT EDH.DepartmentID, D.Name, EDH.ShiftID,
		EDH.StartDate, EDH.EndDate, MAX(EPH.Rate) AS 'MaxLuong/Gio'
FROM EmployeeDepartmentHistory EDH, Department D, EmployeePayHistory EPH
WHERE EDH.BusinessEntityID = 4
AND EDH.BusinessEntityID = EPH.BusinessEntityID
AND EDH.DepartmentID = D.DepartmentID
AND (EPH.RateChangeDate < EDH.EndDate OR EDH.EndDate IS NULL)
AND EPH.RateChangeDate < GETDATE()
GROUP BY EDH.DepartmentID, D.Name, EDH.ShiftID,
		EDH.StartDate, EDH.EndDate