# --------------------------------------
# --------------------------------------
DROP PROCEDURE IF EXISTS ValidateQuery;
DELIMITER //
CREATE PROCEDURE ValidateQuery(IN qNum INT, IN queryTableName VARCHAR(255))
BEGIN
	DECLARE cname VARCHAR(64);
	DECLARE done INT DEFAULT FALSE;
	DECLARE cur CURSOR FOR SELECT c.column_name FROM information_schema.columns c WHERE
c.table_schema='movies' AND c.table_name=queryTableName;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

	# Add the column fingerprints into a tmp table
	DROP TABLE IF EXISTS cFps;
	CREATE TABLE cFps (
  	  `val` VARCHAR(50) NOT NULL
	)
	ENGINE = InnoDB;

	OPEN cur;
	read_loop: LOOP
		FETCH cur INTO cname;
		IF done THEN
      			LEAVE read_loop;
    		END IF;

		DROP TABLE IF EXISTS ordered_column;
		SET @order_by_c = CONCAT('CREATE TABLE ordered_column as SELECT ', cname, ' FROM ', queryTableName, ' ORDER BY ', cname);
		PREPARE order_by_c_stmt FROM @order_by_c;
		EXECUTE order_by_c_stmt;

		SET @query = CONCAT('SELECT md5(group_concat(', cname, ', "")) FROM ordered_column INTO @cfp');
		PREPARE stmt FROM @query;
		EXECUTE stmt;

		INSERT INTO cFps values(@cfp);
		DROP TABLE IF EXISTS ordered_column;
	END LOOP;
	CLOSE cur;

	# Order fingerprints
	DROP TABLE IF EXISTS oCFps;
	SET @order_by = 'CREATE TABLE oCFps as SELECT val FROM cFps ORDER BY val';
	PREPARE order_by_stmt FROM @order_by;
	EXECUTE order_by_stmt;

	# Read the values of the result
	SET @q_yours = 'SELECT md5(group_concat(val, "")) FROM oCFps INTO @yours';
	PREPARE q_yours_stmt FROM @q_yours;
	EXECUTE q_yours_stmt;

	SET @q_fp = CONCAT('SELECT fp FROM fingerprints WHERE qnum=', qNum,' INTO @rfp');
	PREPARE q_fp_stmt FROM @q_fp;
	EXECUTE q_fp_stmt;

	SET @q_diagnosis = CONCAT('select IF(@rfp = @yours, "OK", "ERROR") into @diagnosis');
	PREPARE q_diagnosis_stmt FROM @q_diagnosis;
	EXECUTE q_diagnosis_stmt;

	INSERT INTO results values(qNum, @rfp, @yours, @diagnosis);

	DROP TABLE IF EXISTS cFps;
	DROP TABLE IF EXISTS oCFps;
END//
DELIMITER ;

# --------------------------------------

# Execute queries (Insert here your queries).

# Validate the queries
drop table if exists results;
CREATE TABLE results (
  `qnum` INTEGER  NOT NULL,
  `rfp` VARCHAR(50)  NOT NULL,
  `yours` VARCHAR(50)  NOT NULL,
  `diagnosis` VARCHAR(10)  NOT NULL
)
ENGINE = InnoDB;


# -------------
# Q1
drop table if exists q;
create table q as # Do NOT delete this line. Add the query below.

SELECT m.title AS Movie_Title
FROM actor a, movie m, genre g, role r, movie_has_genre mg
WHERE a.last_name = 'Allen' AND g.genre_name = 'Comedy'AND m.movie_id = r.movie_id AND m.movie_id = mg.movie_id AND a.actor_id = r.actor_id AND g.genre_id = mg.genre_id
;

CALL ValidateQuery(1, 'q');
drop table if exists q;
# -------------


# -------------
# Q2
drop table if exists q;
create table q as # Do NOT delete this line. Add the query below.

SELECT DISTINCT d1.last_name AS Director_Last_Name, m1.title AS Movie_Title
FROM actor a, movie m1, director d1, movie_has_director md1, role r, genre g1, movie_has_genre mg1
WHERE a.last_name = 'Allen' AND a.actor_id = r.actor_id AND r.movie_id = m1.movie_id AND d1.director_id = md1.director_id AND md1.movie_id = m1.movie_id AND g1.genre_id = mg1.genre_id AND mg1.movie_id = m1.movie_id
AND EXISTS(
	SELECT m2.movie_id
	FROM movie m2, genre g2, movie_has_genre mg2, director d2, movie_has_director md2
	WHERE g2.genre_name <> g1.genre_name AND g2.genre_id = mg2.genre_id AND mg2.movie_id = m2.movie_id AND d2.director_id = md2.director_id AND md2.movie_id = m2.movie_id AND d2.director_id = d1.director_id
	)
;

CALL ValidateQuery(2, 'q');
drop table if exists q;
# -------------


# -------------
# Q3
drop table if exists q;
create table q as # Do NOT delete this line. Add the query below.

SELECT a1.last_name AS Actor_Last_Name
FROM actor a1, movie m1, director d1, role r1, movie_has_director md1
WHERE a1.last_name = d1.last_name AND a1.actor_id = r1.actor_id AND r1.movie_id = m1.movie_id AND m1.movie_id = md1.movie_id AND md1.director_id = d1.director_id AND EXISTS(
	SELECT m2.movie_id
	FROM director d2, movie_has_director md2, movie m2, role r2, genre g2, movie_has_genre mg2
	WHERE d2.last_name <> a1.last_name AND a1.actor_id = r2.actor_id AND r2.movie_id = m2.movie_id AND m2.movie_id = md2.movie_id AND md2.director_id = d2.director_id AND g2.genre_id = mg2.genre_id
		AND mg2.movie_id = m2.movie_id AND g2.genre_name IN(
			SELECT g3.genre_name
			FROM actor a3, role r3, movie m3, movie_has_director md3, genre g3, movie_has_genre mg3
			WHERE a3.actor_id <> a1.actor_id AND m3.movie_id <> m1.movie_id AND md3.director_id = d1.director_id AND a3.actor_id = r3.actor_id AND r3.movie_id = m3.movie_id AND m3.movie_id = md3.movie_id
				AND mg3.movie_id = m3.movie_id AND mg3.genre_id = g3.genre_id
			)
		)
;

CALL ValidateQuery(3, 'q');
drop table if exists q;
# -------------


# -------------
# Q4
drop table if exists q;
create table q as # Do NOT delete this line. Add the query below.

SELECT 'yes' AS Answer
FROM movie m
WHERE EXISTS(
	SELECT m.movie_id
	FROM movie m, movie_has_genre mg, genre g
	WHERE  m.movie_id = mg.movie_id AND mg.genre_id = g.genre_id  AND m.year = 1995 AND g.genre_name = 'Drama'
	)
UNION
SELECT 'no' AS Answer
FROM movie m
WHERE NOT EXISTS(
	SELECT m.movie_id
	FROM movie m, movie_has_genre mg, genre gm 
	WHERE  m.movie_id = mg.movie_id AND mg.genre_id = g.genre_id  AND m.year = 1995 AND g.genre_name = 'Drama'
	)
;

CALL ValidateQuery(4, 'q');
drop table if exists q;
# -------------


# -------------
# Q5
drop table if exists q;
create table q as # Do NOT delete this line. Add the query below.

SELECT d1.last_name AS Director_Last_Name_1, d2.last_name AS Director_Last_Name_2
FROM director d1, director d2, movie_has_director md1, movie_has_director md2, movie m, movie_has_genre mg, genre g
WHERE m.year > 2000 AND m.year < 2006 AND d1.director_id < d2.director_id AND d1.director_id = md1.director_id AND d2.director_id = md2.director_id AND md1.movie_id = m.movie_id
	AND md2.movie_id = m.movie_id AND m.movie_id = mg.movie_id AND mg.genre_id = g.genre_id
GROUP BY d1.director_id, d2.director_id
HAVING COUNT(g.genre_id) > 5
;

CALL ValidateQuery(5, 'q');
drop table if exists q;
# -------------


# -------------
# Q6
drop table if exists q;
create table q as # Do NOT delete this line. Add the query below.

SELECT a.first_name AS Actor_First_Name, a.last_name AS Actor_Last_Name, COUNT(DISTINCT d.director_id) AS No_Of_Directors
FROM actor a, role r, movie m, movie_has_director md, director d
WHERE a.actor_id = r.actor_id AND r.movie_id = m.movie_id AND m.movie_id = md.movie_id AND md.director_id = d.director_id
GROUP BY a.actor_id
HAVING COUNT(DISTINCT m.movie_id) = 3
;

CALL ValidateQuery(6, 'q');
drop table if exists q;
# -------------


# -------------
# Q7
drop table if exists q;
create table q as # Do NOT delete this line. Add the query below.

SELECT g.genre_id AS Genre, COUNT(DISTINCT d.director_id) AS No_Of_Directors
FROM movie m1, movie m2, movie_has_director md, director d, genre g, movie_has_genre mg1, movie_has_genre mg2
WHERE m2.movie_id = md.movie_id AND md.director_id = d.director_id AND m2.movie_id = mg2.movie_id AND mg2.genre_id = g.genre_id AND m1.movie_id = mg1.movie_id AND mg1.genre_id = g.genre_id AND m1.movie_id IN(
	SELECT m3.movie_id
	FROM movie m3, movie_has_genre mg3, genre g3
	WHERE m3.movie_id = mg3.movie_id AND mg3.genre_id = g3.genre_id
	GROUP BY m3.movie_id
	HAVING COUNT(g3.genre_name) = 1
	)
GROUP BY g.genre_id
;


CALL ValidateQuery(7, 'q');
drop table if exists q;
# -------------


# -------------
# Q8
drop table if exists q;
create table q as # Do NOT delete this line. Add the query below.

SELECT a.actor_id AS Actor
FROM actor a
WHERE NOT EXISTS(
	SELECT g.genre_id
	FROM genre g
	WHERE NOT EXISTS(
		SELECT m2.movie_id
		FROM role r2, movie m2, genre g2, movie_has_genre mg2
		WHERE a.actor_id = r2.actor_id AND r2.movie_id = m2.movie_id AND m2.movie_id = mg2.movie_id AND mg2.genre_id = g.genre_id
	)
)
;

CALL ValidateQuery(8, 'q');
drop table if exists q;
# -------------


# -------------
# Q9
drop table if exists q;
create table q as # Do NOT delete this line. Add the query below.

SELECT g1.genre_id AS Genre_1, g2.genre_id AS Genre_2 , COUNT(d.director_id) AS No_Of_Directors
FROM  genre g1, genre g2, director d
WHERE g1.genre_id < g2.genre_id AND d.director_id IN(
	SELECT d1.director_id
	FROM movie m1, movie m2, movie_has_genre mg1, movie_has_genre mg2, director d1, movie_has_director md1, movie_has_director md2
	WHERE m1.movie_id = mg1.movie_id AND m2.movie_id = mg2.movie_id AND mg2.genre_id = g2.genre_id AND mg1.genre_id=g1.genre_id AND d1.director_id=md1.director_id
		AND md1.movie_id=m1.movie_id AND d1.director_id=md2.director_id AND md2.movie_id=m2.movie_id
	)
GROUP BY g1.genre_id,g2.genre_id
;


CALL ValidateQuery(9, 'q');
drop table if exists q;
# -------------


# -------------
# Q10
drop table if exists q;
create table q as # Do NOT delete this line. Add the query below.

SELECT g.genre_id AS Genre, a.actor_id AS Actor, COUNT(m.movie_id) AS No_Of_Movies
FROM actor a, movie m, genre g, role r, movie_has_genre mg
WHERE a.actor_id = r.actor_id AND r.movie_id = m.movie_id AND m.movie_id = mg.movie_id AND mg.genre_id = g.genre_id AND g.genre_id = ALL(
	SELECT g2.genre_id
	FROM genre g2, director d2, movie m2, movie_has_genre mg2, movie_has_director md2, movie_has_director md3
	WHERE g2.genre_id = mg2.genre_id AND mg2.movie_id = m2.movie_id AND m2.movie_id = md2.movie_id AND md2.director_id = d2.director_id AND d2.director_id = md3.director_id AND md3.movie_id = m.movie_id
	)
GROUP BY g.genre_id, a.actor_id
;


CALL ValidateQuery(10, 'q');
drop table if exists q;
# -------------

DROP PROCEDURE IF EXISTS RealValue;
DROP PROCEDURE IF EXISTS ValidateQuery;
DROP PROCEDURE IF EXISTS RunRealQueries;
