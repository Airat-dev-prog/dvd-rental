--Задание 1. Напишите SQL-запрос, который выводит всю информацию о фильмах со специальным атрибутом (поле special_features) равным “Behind the Scenes”.
--explain analyze 
select *
from public.film
where 'Behind the Scenes' = any (film.special_features) 
;--Execution Time: 0.432 ms

/* Задание 2. Напишите ещё 2 варианта поиска фильмов с атрибутом “Behind the Scenes”, 
используя другие функции или операторы языка SQL для поиска значения в массиве. */
--explain analyze 
select *
from public.film
where film.special_features && array['Behind the Scenes']
;--Execution Time: 0.476 ms
explain analyze 
select *
from public.film
where array_position(film.special_features, 'Behind the Scenes')>0 
;--Execution Time: 0.536 ms

/* Задание 3. Для каждого покупателя посчитайте, сколько он брал в аренду фильмов со специальным атрибутом “Behind the Scenes”.
Обязательное условие для выполнения задания: используйте запрос из задания 1, помещённый в CTE. */
--explain analyze 
with spec_film as (
	select *
	from public.film
	where 'Behind the Scenes' = any (film.special_features) 
)
select customer.last_name || ' ' || customer.first_name, count(rental.customer_id)
from spec_film
inner join public.inventory on spec_film.film_id = inventory.film_id 
inner join public.rental on inventory.inventory_id = rental.inventory_id
inner join public.customer on rental.customer_id = customer.customer_id 
group by customer.last_name, customer.first_name 
;-- Execution Time: 15.195 ms

/* Задание 4. Для каждого покупателя посчитайте, сколько он брал в аренду фильмов со специальным атрибутом “Behind the Scenes”.
Обязательное условие для выполнения задания: используйте запрос из задания 1, помещённый в подзапрос, который необходимо использовать для решения задания. */
--explain analyze 
select customer.last_name || ' ' || customer.first_name as full_name, count(rental.customer_id) 
from (select *
	from public.film
	where 'Behind the Scenes' = any (film.special_features) 
)spec_film
inner join public.inventory on spec_film.film_id = inventory.film_id 
inner join public.rental on inventory.inventory_id = rental.inventory_id
inner join public.customer on rental.customer_id = customer.customer_id 
group by customer.last_name, customer.first_name 
;--Execution Time: 16.502 ms

-- Задание 5. Создайте материализованное представление с запросом из предыдущего задания и напишите запрос для обновления материализованного представления.
create materialized view film_count_view as
select customer.last_name || ' ' || customer.first_name as full_name, count(rental.customer_id) 
from (select *
	from public.film
	where 'Behind the Scenes' = any (film.special_features) 
)spec_film
inner join public.inventory on spec_film.film_id = inventory.film_id 
inner join public.rental on inventory.inventory_id = rental.inventory_id
inner join public.customer on rental.customer_id = customer.customer_id 
group by customer.last_name, customer.first_name;

REFRESH MATERIALIZED VIEW film_count_view;

/* Задание 6. С помощью explain analyze проведите анализ скорости выполнения запросов из предыдущих заданий и ответьте на вопросы:
с каким оператором или функцией языка SQL, используемыми при выполнении домашнего задания, поиск значения в массиве происходит быстрее;
какой вариант вычислений работает быстрее: с использованием CTE или с использованием подзапроса. */
-- поиск значения в массиве происходит быстрее с использованием оператора any
-- вариант вычислений с использованием CTE работает быстрее  
 
/*
INSERT INTO public.staff
(staff_id, first_name, last_name, address_id, email, store_id, active, username, "password", last_update, picture)
VALUES(3, 'Vasya', 'Ivanov', 2, 'Vasya@gmail.com', 1, true, 'Vasya', 'password', now(), NULL);
*/
--Задание 7. Используя оконную функцию, выведите для каждого сотрудника сведения о первой его продаже.
select staff.last_name || ' ' || staff.first_name as "Сотрудник"
		, customer.last_name || ' ' || customer.first_name as "Первый покупатель"
		, film.title "Наименование первого фильма"
		, payment.payment_date "Дата первой продажи"
		, payment.amount "Стоимость первой продажи"
from public.staff
left join (
		select distinct payment.staff_id
				, min(payment.payment_date) over (partition by payment.staff_id) as first_payment_date 
		from public.payment
		)first_payment on staff.staff_id = first_payment.staff_id
left join public.payment on first_payment.staff_id = payment.staff_id and first_payment.first_payment_date = payment.payment_date
left join public.rental on payment.rental_id = rental.rental_id
left join public.inventory on rental.inventory_id = inventory.inventory_id
left join public.film on inventory.film_id = film.film_id 
left join public.customer on payment.customer_id = customer.customer_id 
;

/* Задание 8. Для каждого магазина определите и выведите одним SQL-запросом следующие аналитические показатели:
•	день, в который арендовали больше всего фильмов (в формате год-месяц-день);
•	количество фильмов, взятых в аренду в этот день;
•	день, в который продали фильмов на наименьшую сумму (в формате год-месяц-день);
•	сумму продажи в этот день. */
/*
INSERT INTO public.store
(store_id, manager_staff_id, address_id, last_update)
VALUES(3, 3, 4, now());
*/

--explain analyze 
with 
payment_info as (
	select distinct 
			rental_info.store_id
			, rental_info.rental_date
			, rental_info.rental_count
			, payment.payment_date::date as payment_date
			, sum(payment.amount) over (partition by rental_info.store_id, payment.payment_date::date) as payment_sum
	from (
	select 	rental.rental_id
			, inventory.store_id
			, rental.rental_date::date as rental_date
			, count(rental.rental_id) over (partition by inventory.store_id, rental.rental_date::date) as rental_count
	from public.rental  
	inner join public.inventory on rental.inventory_id = inventory.inventory_id
	) as rental_info
	inner join public.payment on rental_info.rental_id = payment.rental_id
),
values_info as (
	select payment_info.store_id
			, max(payment_info.rental_count) as max_rental_count
			, min(payment_info.payment_sum) as min_payment_sum
	from payment_info 
	group by payment_info.store_id
) 
select store.store_id
	, max_rental_count_info.max_rental_count_date
	, values_info.max_rental_count 
	, min_payment_sum_info.min_payment_sum_date
	, values_info.min_payment_sum
from public.store
left join (
	select payment_info.store_id, payment_info.payment_date as min_payment_sum_date
	from payment_info
	inner join values_info on payment_info.store_id = values_info.store_id and payment_info.payment_sum = values_info.min_payment_sum
) as min_payment_sum_info on store.store_id = min_payment_sum_info.store_id 
left join (
	select payment_info.store_id, payment_info.rental_date as max_rental_count_date
	from payment_info
	inner join values_info on payment_info.store_id = values_info.store_id and payment_info.rental_count = values_info.max_rental_count
)as max_rental_count_info on store.store_id = max_rental_count_info.store_id
left join values_info on store.store_id = values_info.store_id
;
