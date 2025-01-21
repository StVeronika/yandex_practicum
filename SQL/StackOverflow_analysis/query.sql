-- Выведите общую сумму просмотров у постов, опубликованных в каждый месяц 2008 года. Если данных за какой-либо месяц в базе нет, такой месяц можно пропустить.
-- Результат отсортируйте по убыванию общего количества просмотров.

SELECT DATE_TRUNC('month', creation_date)::date AS dt,
       SUM(views_count)
FROM stackoverflow.posts
GROUP BY DATE_TRUNC('month', creation_date)::date
ORDER BY SUM(views_count) DESC;


-- Выведите имена самых активных пользователей, которые в первый месяц после регистрации (включая день регистрации) дали больше 100 ответов.
-- Вопросы, которые задавали пользователи, не учитывайте. Для каждого имени пользователя выведите количество уникальных значений user_id. 
-- Отсортируйте результат по полю с именами в лексикографическом порядке.

SELECT u.display_name,
       COUNT(DISTINCT user_id)
FROM stackoverflow.posts p
JOIN stackoverflow.post_types pt ON p.post_type_id = pt.id
JOIN stackoverflow.users u ON u.id = p.user_id
WHERE DATE_TRUNC('day', p.creation_date) >= DATE_TRUNC('day', u.creation_date)
  AND DATE_TRUNC('day', p.creation_date) <= DATE_TRUNC('day', u.creation_date) + INTERVAL '1 month'
  AND pt.type = 'Answer'
GROUP BY u.display_name
HAVING COUNT(DISTINCT p.id) > 100
ORDER BY display_name;


-- Выведите количество постов за 2008 год по месяцам. Отберите посты от пользователей, которые зарегистрировались в сентябре 2008 года
-- и сделали хотя бы один пост в декабре того же года. Отсортируйте таблицу по значению месяца по убыванию.

WITH users AS (
    SELECT u.id AS user_id
    FROM stackoverflow.users u
    JOIN stackoverflow.posts p ON u.id=p.user_id
    WHERE u.creation_date::date BETWEEN '2008-09-01' AND '2008-09-30'
    AND p.creation_date::date BETWEEN '2008-12-01' AND '2008-12-31')
    
SELECT DATE_TRUNC('month', creation_date)::date AS dt,
       COUNT(DISTINCT id) AS posts_cnt
FROM stackoverflow.posts
WHERE user_id IN (SELECT user_id FROM users)
GROUP BY DATE_TRUNC('month', creation_date)::date
ORDER BY dt DESC;


-- Используя данные о постах, выведите несколько полей:
 - идентификатор пользователя, который написал пост;
 - дата создания поста;
 - количество просмотров у текущего поста;
 - сумма просмотров постов автора с накоплением.
Данные в таблице должны быть отсортированы по возрастанию идентификаторов пользователей,
-- а данные об одном и том же пользователе — по возрастанию даты создания поста.
   
SELECT user_id,
       creation_date,
       views_count,
       SUM(views_count) OVER (PARTITION BY user_id ORDER BY creation_date)
FROM stackoverflow.posts
GROUP BY user_id, creation_date, views_count
ORDER BY user_id, creation_date;


-- Сколько в среднем дней в период с 1 по 7 декабря 2008 года включительно пользователи взаимодействовали с платформой?
-- Для каждого пользователя отберите дни, в которые он или она опубликовали хотя бы один пост.
-- Нужно получить одно целое число — не забудьте округлить результат.

WITH active_days AS (
    SELECT user_id,
           COUNT(DISTINCT creation_date::date) AS days_cnt
    FROM stackoverflow.posts
    WHERE creation_date::date BETWEEN '2008-12-01' AND '2008-12-07'
    GROUP BY user_id)
 
SELECT ROUND(AVG(days_cnt))
FROM active_days;


-- На сколько процентов менялось количество постов ежемесячно с 1 сентября по 31 декабря 2008 года? Отобразите таблицу со следующими полями:
 - Номер месяца.
 - Количество постов за месяц.
 - Процент, который показывает, насколько изменилось количество постов в текущем месяце по сравнению с предыдущим.
 - Если постов стало меньше, значение процента должно быть отрицательным, если больше — положительным. Округлите значение процента до двух знаков после запятой.
 - Напомним, что при делении одного целого числа на другое в PostgreSQL в результате получится целое число, округлённое до ближайшего целого вниз.
-- Чтобы этого избежать, переведите делимое в тип numeric. 
  
WITH month_data AS (
SELECT EXTRACT(MONTH FROM creation_date::date) AS month_num,
       COUNT(id) AS posts_cnt
FROM stackoverflow.posts
WHERE EXTRACT(MONTH FROM creation_date::date) BETWEEN 9 AND 12
GROUP BY EXTRACT(MONTH FROM creation_date::date))

SELECT month_num,
       posts_cnt,
       ROUND((posts_cnt::numeric / LAG(posts_cnt, 1) OVER (ORDER BY month_num) - 1) *100 , 2) AS posts_growth
FROM month_data;



-- Найдите пользователя, который опубликовал больше всего постов за всё время с момента регистрации.
-- Выведите данные его активности за октябрь 2008 года в таком виде:
  - номер недели;
  - дата и время последнего поста, опубликованного на этой неделе.
    
  WITH top_user AS (
SELECT user_id, 
       COUNT(id) AS post_count
FROM stackoverflow.posts
GROUP BY user_id
ORDER BY post_count DESC
LIMIT 1),
     
     top_users_posts AS (
SELECT EXTRACT(WEEK FROM creation_date::date) AS week_num,
       creation_date AS post_dt
FROM stackoverflow.posts
WHERE user_id IN (SELECT user_id FROM top_user)
AND creation_date::date BETWEEN '2008-10-01' AND '2008-10-31'
ORDER BY EXTRACT(WEEK FROM creation_date::date))

SELECT DISTINCT
       week_num,
       MAX(post_dt) OVER(PARTITION BY week_num) AS last_week_post
FROM top_users_posts;
  
