  select cast(day as date) day,first_deny_index,first_deny_reason
  ,user_pay_status_business,active_user_attribution
,grade,gender,channel,u_from,regist_os,province,city_class,city,real_identity
  ,concat_ws('-',first_deny_index,first_deny_reason) tag
  ,count(distinct push_u_user) cnt
  from aws.crm_active_data_pool_day 
  where day>=20230701
  and enter_datapool_u_user is null and first_deny_reason is not null
  group by day,first_deny_index,first_deny_reason,user_pay_status_business,active_user_attribution
,grade,gender,channel,u_from,regist_os,province,city_class,city,real_identity
,concat_ws('-',first_deny_index,first_deny_reason)
  order by day,first_deny_index
