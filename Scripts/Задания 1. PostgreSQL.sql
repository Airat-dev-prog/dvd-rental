--Задание 1. Выведите уникальные названия городов из таблицы городов.
select distinct c.city
from public.city c;

select c.city
from public.city c
group by c.city;

/* Задание 2. Доработайте запрос из предыдущего задания, 
чтобы запрос выводил только те города, 
названия которых начинаются на “L” и заканчиваются на “a”, и названия не содержат пробелов. */
select distinct c.city
from public.city c
where c.city like 'L%a' and split_part(c.city, ' ', 2) = '' ;

select distinct c.city
from public.city c
where c.city like 'L%a' and c.city not like '% %' ;

/* Задание 3. Получите из таблицы платежей за прокат фильмов информацию по платежам,
которые выполнялись в промежуток с 17 июня 2005 года по 19 июня 2005 года включительно 
и стоимость которых превышает 1.00. Платежи нужно отсортировать по дате платежа. */
select *
from public.payment p
where p.payment_date between '2005-06-17' and '2005-06-20' -- тут время 00:00:00
and p.amount > 1
order by p.payment_date ;

--Задание 4. Выведите информацию о 10-ти последних платежах за прокат фильмов.
select *
from public.payment p 
order by p.payment_date desc 
limit 10 ;

/* Задание 5. Выведите следующую информацию по покупателям:
•	Фамилия и имя (в одной колонке через пробел)
•	Электронная почта
•	Длину значения поля email
•	Дату последнего обновления записи о покупателе (без времени)
 Каждой колонке задайте наименование на русском языке. */
select cu.last_name || ' ' || cu.first_name as "Фамилия и имя"
		, cu.email as "Электронная почта"
		, length(cu.email) as "Длина значения поля email"
		, cu.last_update :: date as  "Дата последнего обновления записи о покупателе"
from public.customer cu ;

/* Задание 6. Выведите одним запросом только активных покупателей, 
имена которых KELLY или WILLIE. 
Все буквы в фамилии и имени из верхнего регистра должны быть переведены в нижний регистр. */
select *
from public.customer cu 
where cu.active = 1 and cu.first_name in ('KELLY', 'WILLIE') ;

/* Задание 7. Выведите одним запросом информацию о фильмах, у которых рейтинг “R” 
и стоимость аренды указана от 0.00 до 3.00 включительно, 
а также фильмы c рейтингом “PG-13” и стоимостью аренды больше или равной 4.00. */

--Задание 8. Получите информацию о трёх фильмах с самым длинным описанием фильма.
select *  
from public.film fm
order by length(fm.description) desc 
limit 3
;

/* Задание 9. Выведите Email каждого покупателя, разделив значение Email на 2 отдельных колонки:
•	в первой колонке должно быть значение, указанное до @,
•	во второй колонке должно быть значение, указанное после @. */
select split_part(cu.email, '@', 1), split_part(cu.email, '@', 2)
from public.customer cu ;

/* Задание 10. Доработайте запрос из предыдущего задания, 
 * скорректируйте значения в новых колонках: первая буква должна быть заглавной, остальные строчными. */
select concat(
		upper(left(split_part(split_part(cu.email, '@', 1), '.', 1),1)) || lower(substr(split_part(split_part(cu.email, '@', 1), '.', 1),2)) 
		, '.' ,
		upper(left(split_part(split_part(cu.email, '@', 1), '.', 2),1)) || lower(substr(split_part(split_part(cu.email, '@', 1), '.', 2),2)) 
		)
	, split_part(cu.email, '@', 2)
from public.customer cu ;
