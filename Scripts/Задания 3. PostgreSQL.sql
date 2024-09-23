/* Задание 1. Сделайте запрос к таблице payment и с помощью оконных функций добавьте вычисляемые колонки согласно условиям:
•	Пронумеруйте все платежи от 1 до N по дате
•	Пронумеруйте платежи для каждого покупателя, сортировка платежей должна быть по дате
•	Посчитайте нарастающим итогом сумму всех платежей для каждого покупателя, сортировка должна быть сперва по дате платежа, 
	а затем по сумме платежа от наименьшей к большей
•	Пронумеруйте платежи для каждого покупателя по стоимости платежа от наибольших к меньшим так, 
	чтобы платежи с одинаковым значением имели одинаковое значение номера.
Можно составить на каждый пункт отдельный SQL-запрос, а можно объединить все колонки в одном запросе. */
-- на каждый пункт составил отдельный SQL-запрос, потому что так нагляднее видеть результат выполнения
select *, row_number () over (order by payment_date  ) from public.payment ;
select *, row_number() over (partition by customer_id order by payment_date ) 
		, sum(amount) over (partition by customer_id  order by payment_date, amount) 
from public.payment ;
select *, rank() over (partition by customer_id order by amount desc) from public.payment ; 

/* Задание 2. С помощью оконной функции выведите для каждого покупателя стоимость платежа 
 и стоимость платежа из предыдущей строки со значением по умолчанию 0.0 с сортировкой по дате. */
select *, amount , lag(amount, 1, 0.0) over (partition by customer_id order by payment_date)
from public.payment ;

--Задание 3. С помощью оконной функции определите, на сколько каждый следующий платеж покупателя больше или меньше текущего.
-- отрицательная сумма показывает на сколько меньше
select *, lead(amount, 1, 0.0) over (partition by customer_id order by payment_date) - amount 
from public.payment ;

--Задание 4. С помощью оконной функции для каждого покупателя выведите данные о его последней оплате аренды.
select distinct customer_id, max(payment_date) over (partition by customer_id) 
from public.payment 
order by customer_id;

/* Задание 5. С помощью оконной функции выведите для каждого сотрудника сумму продаж за август 2005 года 
 с нарастающим итогом по каждому сотруднику и по каждой дате продажи (без учёта времени) с сортировкой по дате. */
select distinct payment.staff_id, payment.payment_date::date--, payment.amount
		, sum(payment.amount) over (partition by payment.staff_id, payment.payment_date::date) as "сумма продавца за день"
		, sum(payment.amount) over (partition by payment.staff_id order by payment.payment_date::date) as "сумма продавца за первые N дней"
		, sum(payment.amount) over (partition by payment.staff_id) as "сумма продавца за период"
from public.payment
where payment.payment_date between '01-08-2005' and '01-09-2005'
order by payment.staff_id, payment.payment_date::date 
;

/* Задание 6. 20 августа 2005 года в магазинах проходила акция: покупатель каждого сотого платежа получал дополнительную скидку на следующую аренду. 
 С помощью оконной функции выведите всех покупателей, которые в день проведения акции получили скидку. */
select customers.customer_id 
from (
	select payment.customer_id 
			,row_number() over (order by payment.payment_id)%100 = 0 as got_discount
	from public.payment
	where payment.payment_date between '20-08-2005' and '21-08-2005'
)as customers where got_discount
;

/* Задание 7. Для каждой страны определите и выведите одним SQL-запросом покупателей, которые попадают под условия:
•	покупатель, арендовавший наибольшее количество фильмов;
•	покупатель, арендовавший фильмов на самую большую сумму;
•	покупатель, который последним арендовал фильм. */

with info as (
	select city.country_id, customer.customer_id
			, count(rental.*)  as count_film
			, sum(payment.amount) as total_rent_summ
			, max(rental.rental_date) as last_rent_date
	from public.customer
	inner join public.address on customer.address_id  = address.address_id 
	inner join public.city on address.city_id = city.city_id 
	inner join public.rental on customer.customer_id  = rental.customer_id
	inner join public.payment on rental.rental_id = payment.rental_id
	group by city.country_id, customer.customer_id
),
max_values as (
	select info.country_id  
			, max(info.count_film) as max_count_film  
			, max(info.total_rent_summ) as max_total_rent_summ  
			, max(info.last_rent_date) as max_last_rent_date  
	from info
	group by info.country_id
)
select country.country
		, max_count_film_customer.last_name || ' ' || max_count_film_customer.first_name as "наибольшее количество фильмов"
		, max_total_rent_summ_customer.last_name || ' ' || max_total_rent_summ_customer.first_name as "самая большая сумма"
		, last_rent_date_customer.last_name || ' ' || last_rent_date_customer.first_name as "последняя аренда фильм"
from public.country
--
inner join(
	select info.country_id, info.customer_id
	from  info 
	inner join max_values as max_count_film_values 
				on info.country_id = max_count_film_values.country_id 
					and info.count_film = max_count_film_values.max_count_film
)as res_count_film on country.country_id = res_count_film.country_id
inner join public.customer as max_count_film_customer on res_count_film.customer_id = max_count_film_customer.customer_id
--
inner join(
	select info.country_id, info.customer_id
	from  info 
	inner join max_values as max_total_rent_summ_values 
				on info.country_id = max_total_rent_summ_values.country_id 
					and info.total_rent_summ = max_total_rent_summ_values.max_total_rent_summ
)as res_total_rent_summ on country.country_id = res_total_rent_summ.country_id
inner join public.customer as max_total_rent_summ_customer on res_total_rent_summ.customer_id = max_total_rent_summ_customer.customer_id
--
inner join(
	select info.country_id, info.customer_id
	from  info 
	inner join max_values as max_last_rent_date_values 
				on info.country_id = max_last_rent_date_values.country_id 
					and info.last_rent_date = max_last_rent_date_values.max_last_rent_date
)as res_last_rent_date on country.country_id = res_last_rent_date.country_id
inner join public.customer as last_rent_date_customer on res_last_rent_date.customer_id = last_rent_date_customer.customer_id 
;
