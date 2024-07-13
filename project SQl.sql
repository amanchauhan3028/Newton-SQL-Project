-- Segment 1:Database - Tables, Columns, Relationships ------------------------------------------------------------------------------------------------------------
-- 1 What are the different tables in the database and how are they connected to each other in the database?

-- 2 Find the total number of rows in each table of the schema.
select table_name,table_rows from information_schema.tables where table_schema = 'imdb';
select count(*) from director_mapping;
select count(*) from genre;

-- 3 Identify which columns in the movie table have null values.
select column_name from information_schema.columns
where table_name = 'movies'
and table_schema = 'imdb'
and is_nullable = 'YES';
select count(*) from movies;

-- Segment 2: Movie Release Trends------------------------------------------------------------------------------------------------------------------------------------

-- 1 Determine the total number of movies released each year and analyse the month-wise trend.
select year, count(id) from movies group by year;
with cte as (
	select 
	month(STR_TO_DATE(date_published, '%m/%d/%Y')) as mnth, count(id) as cnt_mov
	from movies 
	group by mnth 
	order by mnth
), cte2 as (
	select 
	*, 
	lag(cnt_mov) over(order by mnth) as prev_mt_count 
	from cte
) select mnth, cnt_mov, round((cnt_mov-prev_mt_count)/cnt_mov*100,2) as percentage
	from cte2;
-- 2 Calculate the number of movies produced in the USA or India in the year 2019.
select 
	count(*) 
from 
	movies 
where 
	year=2019 
    and 
    country in ("USA","India");
    
    -- Segment 3: Production Statistics and Genre Analysis----------------------------------------------------------------------------------------------------------------------

-- 1 Retrieve the unique list of genres present in the dataset.
select distinct genre from genre;
-- 2 Identify the genre with the highest number of movies produced overall.
select genre, count(movie_id) as no_movie from  genre group by genre order by no_movie desc limit 1;
-- 3 Determine the count of movies that belong to only one genre.
with cte as(
	select 
		movie_id , 
        count(genre) as cnt
	from 
		genre 
	group by 
		movie_id)
        select count(movie_id) as num_mov_one_genre  from cte where cnt=1 ;
-- 4 Calculate the average duration of movies in each genre.
select 
	genre , 
    avg(m.duration) as avg_duration  
from 
	genre g 
inner join 
	movies m on g.movie_id=m.id 
group by 
	genre;
-- 5 Find the rank of the 'thriller' genre among all genres in terms of the number of movies produced.
with cte as (
select 
	genre , 
    count(*) as movie_count
from 
	genre g 
group by 
	genre),cte2 as 
    (select * , 
	rank() over(order by movie_count desc) as rnk
from 
	 cte)select * from cte2 where genre ="thriller";
     
    
-- Segment 4: Ratings Analysis and Crew Members------------------------------------------------------------------------------------------------------------------------------


-- 1 Retrieve the minimum and maximum values in each column of the ratings table (except movie_id).
select 
	min(avg_rating) as min_avg_rating,
    min(total_votes) as min_total_votes,
    min(median_rating) as min_median_rating,
	max(avg_rating) as max_vg_rating,
    max(total_votes) as max_total_votes,
    max(median_rating) as miax_median_rating
from ratings;
-- 2 Identify the top 10 movies based on average rating.
select movie_id , avg_rating from ratings order by avg_rating desc limit 10;
-- 3 Summarise the ratings table based on movie counts by median ratings.
select median_rating , count(*) as movie_count from ratings group by median_rating order by median_rating;
-- 4 Identify the production house that has produced the most number of hit movies (average rating > 8)
select 
	production_company as production_house,
    avg_rating 
from 
	ratings r 
inner join 
	movies m on r.movie_id = m.id 
where 
	avg_rating>8;
-- 5 Determine the number of movies released in each genre during March 2017 in the USA with more than 1,000 votes.
select 
	genre , 
	count(id) 
from 
	ratings r 
inner join 
	movies m on r.movie_id = m.id 
inner join 
	genre g on g.movie_id=m.id
where year =2017
and
country="USA"
and 
total_votes>1000;

-- 6 Retrieve movies of each genre starting with the word 'The' and having an average rating > 8.
select 
	title, 
    genre , 
    avg_rating 
from 
	movies m 
inner join ratings r
	on m.id=r.movie_id
inner join genre g
	on m.id=g.movie_id
where  avg_rating > 8
	and title like 'The%';
    
-- Segment 5: Crew Analysis----------------------------------------------------------------------------------------------------------------------------------------------

-- -	Identify the columns in the names table that have null values.
select * from names;
-- 2 Determine the top three directors in the top three genres with movies having an average rating > 8.
with cte as (
select 
	genre
   from genre g 
inner join ratings r on g.movie_id=r.movie_id
where avg_rating>8
group by genre 
order by count(r.movie_id) desc limit 3), cte2 as (
select 
	genre , 
    name as director,
    row_number() over(partition by genre order by avg_rating desc ) rnk 
from genre g 
inner join ratings r on g.movie_id=r.movie_id
inner join director_mapping dm on r.movie_id=dm.movie_id
inner join names n on dm.name_id=n.id 
where genre in (select * from cte))
select * from cte2 where rnk<4;
-- 3 Find the top two actors whose movies have a median rating >= 8.
select 
	name
from 
	names n
join role_mapping rm 
	on n.id=rm.name_id
join ratings r
	on rm.movie_id=r.movie_id
where median_rating>=8 and category="actor"
order by median_rating desc limit 2;
    
-- 4 Identify the top three production houses based on the number of votes received by their movies.
with cte as (
select 
	production_company,
    dense_rank() over(order by total_votes) as rnk
from movies m 
inner join ratings r
	on m.id=r.movie_id
)select * from cte limit 3;
-- 5 Rank actors based on their average ratings in Indian movies released in India.
select name_id,name ,
	dense_rank() over(order by avg_rating) as rnk
from 
	role_mapping rm
inner join 
	ratings r
	on rm.movie_id=r.movie_id 
inner join movies m
	on r.movie_id=m.id
inner join names n
	on rm.name_id=n.id
where 
	country="india" and category="Actor" or category="actress";
    
-- 6 Identify the top five actresses in Hindi movies released in India based on their average ratings.
select 
	name ,
	dense_rank() over(order by avg_rating desc) as rnk
from 
	role_mapping rm
inner join ratings r
	on rm.movie_id=r.movie_id 
inner join movies m
	on r.movie_id=m.id
inner join names n
	on rm.name_id=n.id
where 
	country="india" and category="actress" and languages ="hindi"
limit 5;

-- Segment 6: Broader Understanding of Data------------------------------------------------------------------------------------------------------------------------------

-- 1  Classify thriller movies based on average ratings into different categories.
select 
	g.genre ,
	rm.category,
    avg(r.avg_rating)as avge_rating
from role_mapping rm 
inner join genre g on  rm.movie_id=g.movie_id
inner join ratings r on g.movie_id=r.movie_id 
where genre ="thriller"
group by genre ,category
 ;
-- 2 analyse the genre-wise running total and moving average of the average movie duration.
with cte as (
	select 
		genre ,
        sum(duration) as total_duration ,
        avg(duration) as avg_duration
	from 
		genre g
	join movies m
		on g.movie_id=m.id
	group by genre 
)select 
	genre ,
    sum(total_duration) over( order by genre rows between unbounded preceding and current row) as runing_total,
    avg(avg_duration) over(  order by genre rows between unbounded preceding and current row) as moving_average
from 
	cte;
-- 3 Identify the five highest-grossing movies of each year that belong to the top three genres.
with cte as (
select 
	genre
   from genre g 
inner join ratings r on g.movie_id=r.movie_id
group by genre 
order by count(r.movie_id) desc limit 3), cte2 as (
select 
	year,
    title,  
    row_number() over(partition by YEAR ORDER BY avg_rating desc) rnk 
from genre g
inner join movies m on g.movie_id=m.id
inner join ratings r on m.id=r.movie_id
where genre in (select * from cte)
) select * from cte2 where rnk <6;

-- 4 Determine the top two production houses that have produced the highest number of hits among multilingual movies.
select 
    production_company,
    count(*) cnt
 from movies m
 inner join ratings r on r.movie_id =m.id
 where locate(',',languages)>0 and avg_rating >8 and production_company !=""
 group by production_company
 order by cnt desc 
 limit 2;
-- 5 Identify the top three actresses based on the number of Super Hit movies (average rating > 8) in the drama genre.
select 
	name as actresses_name,
    genre,
    avg_rating
from 
	role_mapping rm
inner join ratings r on rm.movie_id=r.movie_id 
inner join names n on rm.name_id=n.id
inner join genre g on r.movie_id=g.movie_id
where category ="actress" and avg_rating>8 and genre ='drama'
order by avg_rating desc limit 3;

-- 6 Retrieve details for the top nine directors based on the number of movies, including average inter-movie duration, ratings, and more.
with innter_movie_duration as 
(select 
     name_id,
	name as director ,
	STR_TO_DATE(date_published, '%m/%d/%Y') as date_published,
    datediff(str_to_date(lead(date_published) 
    over(partition by name order by STR_TO_DATE(date_published, '%m/%d/%Y') ),'%m/%d/%Y'),STR_TO_DATE(date_published, '%m/%d/%Y') 
     ) as day_diff 
from names n 
inner join director_mapping dm on n.id=dm.name_id
inner join movies m on dm.movie_id=m.id 
)
select 
	name as director ,
	count(dm.movie_id),
    round(avg(avg_rating),2) as ratings,
    day_diff
from names n 
inner join director_mapping dm on n.id=dm.name_id
inner join ratings r on dm.movie_id=r.movie_id
inner join innter_movie_duration imd on dm.name_id=imd.name_id 
group by 1
order by 2 desc limit 9;

-- Segment 7: Recommendations
-- Based on the analysis, provide recommendations for the types of content Bolly Movies should focus on producing.

-- Ans: Based on the Analysis of the IMBd Movies, the recommendations for the types of content Bolly Movies should focus on producing is:-

--           1. The 'Triller' genre has caught the highest attention and interest amongst the audience as the amount of 'Thriller' movies watched is good,
-- 	         so the Bollywood movie production houses should keep their interest towards producing more 'Thriller' genre movies. 
--        
--           2. The 'Drama' genre has gained the overall average highest IMDb rating by the audience, so the Bollywood movies production houses 
--              should focus more on producing quality content movies in the 'Drama' genre as they have been doing.
--        
--           3. The Bollywood movie production houses should also focus on producing good quality movies in other genres as well for the 
--              growth of the bollywood movie industry.
