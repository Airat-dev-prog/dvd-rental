--Задание 1. Выведите для каждого покупателя его адрес, город и страну проживания.
select customer.last_name || ' ' || customer.first_name as "customer full name"
		, address.address 
		, city.city 
		, country.country 
from public.customer 
inner join public.address on customer.address_id = address.address_id 
inner join public.city on address.city_id = city.city_id 
inner join public.country on city.country_id = country.country_id ;

/* Задание 2. С помощью SQL-запроса посчитайте для каждого магазина количество его покупателей.
•	Доработайте запрос и выведите только те магазины, у которых количество покупателей больше 300. 
	Для решения используйте фильтрацию по сгруппированным строкам с функцией агрегации. 
•	Доработайте запрос, добавив в него информацию о городе магазина, фамилии и имени продавца, который работает в нём. */
select city.city "stores sity"
		, staff.last_name || ' ' || staff.first_name as "manager full name"
		, count(customer.*) "customer count"
from public.store 
left join public.customer on store.store_id  = customer.store_id  
inner join public.address on store.address_id = address.address_id 
inner join public.city on address.city_id = city.city_id
inner join public.staff on store.manager_staff_id = staff.staff_id 
group by customer.store_id, city.city, "manager full name"
having count(*) > 300 ;

--Задание 3. Выведите топ-5 покупателей, которые взяли в аренду за всё время наибольшее количество фильмов.
select customer.last_name || ' ' || customer.first_name as "customer full name", count(*) as "rental count" 
from public.customer 
inner join public.rental on rental.customer_id = customer.customer_id 
group by customer.customer_id, customer.last_name, customer.first_name 
order by "rental count" desc
limit 5 ;

/* Задание 4. Посчитайте для каждого покупателя 4 аналитических показателя:
•	количество взятых в аренду фильмов;
•	общую стоимость платежей за аренду всех фильмов (значение округлите до целого числа);
•	минимальное значение платежа за аренду фильма;
•	максимальное значение платежа за аренду фильма. */
select customer.last_name || ' ' || customer.first_name as "customer full name" 
		, count(rental.*) "rental count"
		, round(sum(payment.amount),0) "total summ"
		, min(payment.amount) "min summ"
		, max(payment.amount) "max summ"
from public.customer 
inner join public.rental on customer.customer_id = rental.customer_id 
inner join public.payment on customer.customer_id = payment.customer_id 
group by customer.customer_id, "customer full name" ;

/* Задание 5. Используя данные из таблицы городов, составьте одним запросом всевозможные пары городов так, 
   чтобы в результате не было пар с одинаковыми названиями городов. Для решения необходимо использовать декартово произведение. */
select city.city, city2.city
from public.city
Cross Join public.city city2 
where city.city_id != city2.city_id ;

/* Задание 6. Используя данные из таблицы rental о дате выдачи фильма в аренду (поле rental_date) и дате возврата (поле return_date), 
   вычислите для каждого покупателя среднее количество дней, за которые он возвращает фильмы. */
select customer.last_name || ' ' || customer.first_name as "customer full name", 
		EXTRACT(DAY FROM avg(rental.return_date - rental.rental_date )) as "avg",
		avg( EXTRACT(DAY FROM rental.return_date - rental.rental_date )),
		avg ( rental.return_date - rental.rental_date )
from public.rental 
inner join public.customer on rental.customer_id = customer.customer_id
group by rental.customer_id , "customer full name" ;

--Задание 7. Посчитайте для каждого фильма, сколько раз его брали в аренду, а также общую стоимость аренды фильма за всё время.
select film.title, count(rental.rental_id) "rental count", sum(payment.amount) "total summ"
from public.film 
left join public.inventory on film.film_id = inventory.film_id
left join public.rental on inventory.inventory_id = rental.inventory_id 
left join public.payment on rental.rental_id = payment.rental_id 
group by film.film_id, film.title
;

--Задание 8. Доработайте запрос из предыдущего задания и выведите с помощью него фильмы, которые ни разу не брали в аренду.
select film.title, count(rental.rental_id), sum(payment.amount) 
from public.film 
left join public.inventory on film.film_id = inventory.film_id
left join public.rental on inventory.inventory_id = rental.inventory_id 
left join public.payment on rental.rental_id = payment.rental_id 
group by film.film_id, film.title
having count(rental.rental_id) = 0
;

/* Задание 9. Посчитайте количество продаж, выполненных каждым продавцом. Добавьте вычисляемую колонку «Премия». 
   Если количество продаж превышает 7 300, то значение в колонке будет «Да», иначе должно быть значение «Нет». */
select staff.last_name || ' ' || staff.first_name as "manager full name"
		, count(rental.*)
		, case when count(rental.*)>7300 then 'Да' else 'Нет' end as "Премия"
from public.staff
left join public.rental on staff.staff_id = rental.staff_id 
group by staff.staff_id , "manager full name"
