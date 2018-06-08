# ----- CONFIGURE YOUR EDITOR TO USE 4 SPACES PER TAB ----- #
import pymysql as db
import settings
import sys

def connection():
    ''' User this function to create your connections '''
    con = db.connect(
        settings.mysql_host, 
        settings.mysql_user, 
        settings.mysql_passwd, 
        settings.mysql_schema)
    
    return con

def updateRank(rank1, rank2, movieTitle):

    # Create a new connection
    con=connection()
    
    # Create a cursor on the connection
    cur=con.cursor()

    try:
        float(rank1)
    except ValueError:
        return [("status",),("error",),]
    try:
        float(rank2)
    except ValueError:
        return [("status",),("error",),]

    if float(rank1) < 0 or float(rank1) > 10:
        print("Error: Rank1 must be between 0 and 10.")
        return [("status",),("error",),]
    if float(rank2) < 0 or float(rank2) > 10:
        print("Error: Rank2 must be between 0 and 10.")
        return [("status",),("error",),]

    get_movie = ("SELECT m.rank AS rank FROM movie m WHERE m.title = '%s'") % (movieTitle)
    cur.execute(get_movie)

    result = cur.fetchall()
    if len(result) == 0:
        print("Error: The movie was not found")
        return [("status",),("error",),]
    if len(result) > 1:
        print("Error: More than one movies were found")
        return [("status",),("error",),]

    if result[0] is None:
        avg = (float(rank1)+float(rank2))/2.0
    else:
        avg = (float(rank1)+float(rank2)+result[0][0])/3.0

    update_movie = ("UPDATE movie SET rank = '%f' WHERE movie_id = '%s'") % (avg, movieTitle)

    try:
        cur.execute(update_movie)
        con.commit()
    except:
        print("Error: Failed to update the database")
        con.rollback()
    print (rank1, rank2, movieTitle)
    print (result[0][0], avg)

    con.close()
    return [("status",),("ok",),]


def colleaguesOfColleagues(actorId1, actorId2):

    # Create a new connection
    con=connection()
    
    # Create a cursor on the connection
    cur=con.cursor()

    get_movies = ("""SELECT DISTINCT mcd.title AS title, c.actor_id as C, d.actor_id AS D
    FROM movie mcd, role rcd1, role rcd2, actor c, actor d
    WHERE c.actor_id <> d.actor_id  AND rcd1.actor_id = c.actor_id AND rcd1.movie_id = mcd.movie_id AND rcd2.actor_id = d.actor_id AND rcd2.movie_id = mcd.movie_id AND EXISTS(
    SELECT  * FROM role rac1, role rac2, movie mac WHERE  '%s'= rac1.actor_id  AND rac1.actor_id <> c.actor_id AND rac1.movie_id = mac.movie_id AND c.actor_id = rac2.actor_id AND rac2.movie_id = mac.movie_id
    ) AND EXISTS(
    SELECT * FROM role rbd1, role rbd2, movie mbd WHERE '%s' = rbd1.actor_id AND rbd1.actor_id <> d.actor_id AND rbd1.movie_id = mbd.movie_id AND d.actor_id = rbd2.actor_id AND rbd2.movie_id  = mbd.movie_id
    ) """) % (actorId1, actorId2)
    
    cur.execute(get_movies)
    results = cur.fetchall()

    end_table = []
    end_table.append(("movieTitle", "colleagueOfActor1", "colleagueOfActor2", "actor1", "actor2"))
    for row in results:
       end_table.append((row[0], row[1], row[2], actorId1, actorId2))
    
    print (actorId1, actorId2)
    con.close()
    return end_table
   # return [("movieTitle", "colleagueOfActor1", "colleagueOfActor2", "actor1", "actor2"),]
   
    
def actorPairs(actorId):

    # Create a new connection
    con=connection()
    
    # Create a cursor on the connection
    cur=con.cursor()

    get_genres=("""SELECT DISTINCT COUNT(DISTINCT g.genre_id) AS Count
    FROM role r, movie m, genre g, movie_has_genre mg
    WHERE r.actor_id = '%s' AND r.movie_id = m.movie_id AND m.movie_id = mg.movie_id AND mg.genre_id = g.genre_id""") % (actorId)

    cur.execute(get_genres)
    genre_num = cur.fetchone()

    print(genre_num[0])

    get_actors = ("""SELECT DISTINCT a1.actor_id AS ACTOR
    FROM actor a1, movie m1, role r1, genre g1, movie_has_genre mg1
    WHERE a1.actor_id <> '%s' AND a1.actor_id = r1.actor_id AND r1.movie_id = m1.movie_id AND m1.movie_id = mg1.movie_id AND mg1.genre_id = g1.genre_id
    AND NOT EXISTS(
    SELECT m2.movie_id
    FROM actor a2, movie m2, role r2, genre g2, movie_has_genre mg2
    WHERE a2.actor_id = r2.actor_id AND r2.movie_id = m2.movie_id AND m2.movie_id = mg2.movie_id AND mg2.genre_id = g2.genre_id AND a2.actor_id = a1.actor_id AND g2.genre_id = ANY(
        SELECT g3.genre_id
        FROM actor a3, role r3, movie m3, genre g3, movie_has_genre mg3
        WHERE a3.actor_id = '%s' AND a3.actor_id = r3.actor_id AND r3.movie_id = m3.movie_id AND m3.movie_id = mg3.movie_id AND mg3.genre_id = g3.genre_id 
        )
    )
    GROUP BY r1.actor_id
    HAVING (COUNT(DISTINCT g1.genre_id) >= 7 - '%d')""") % (actorId, actorId, genre_num[0])

    cur.execute(get_actors)
    results = cur.fetchall()
    end_table = []
    end_table.append(("actor2Id",))
    for row in results:
        end_table.append((row))
        
    print (actorId)
    con.close()
    return end_table
    #return [("actor2Id",)]
	
def selectTopNactors(n):

    # Create a new connection
    con=connection()
    
    # Create a cursor on the connection
    cur=con.cursor()
    get_mov = ("""SELECT DISTINCT g.genre_name AS Genre, a.actor_id AS Actor, COUNT(DISTINCT m.movie_id) AS Count
    FROM movie m, actor a, role r, genre g, movie_has_genre mg
    WHERE g.genre_id = mg.genre_id AND mg.movie_id = m.movie_id AND m.movie_id = r.movie_id AND r.actor_id = a.actor_id
    GROUP BY g.genre_name, a.actor_id
    ORDER BY g.genre_name, COUNT(DISTINCT m.movie_id) DESC""")

    cur.execute(get_mov)
    results = cur.fetchall()


    end_table = []
    end_table.append(("genreName", "actorId", "numberOfMovies"))

    i = 0
    cg = results[0][0]
    for row in results:
        if i >= float(n) and row[0] == cg:
            continue

        if row[0] != cg:
            cg = row[0]
            i = 0

        i = i+1
        end_table.append((row[0], row[1], row[2]))


    print (n)
    
    return end_table
