-- =====================================================
-- 资源位转化- 活动资源位看板底层表 tmp.meishihua_activity_operate_2025_middle_2
-- =====================================================
--
-- 【表粒度】
--   见建表sql
--
-- 【业务定位】
--   - 【归属】资源位转化 / 活动资源位看板底层表。
--   - 同tmp.meishihua_activity_operate_2025_middle_1，活动临时资源位配置位

-- 【统计口径】
--   - 同tmp.meishihua_activity_operate_2025_middle_1

-- 【常用关联】
--   - aws.business_user_pay_process_day a join tmp.meishihua_activity_operate_2025_middle_1 b on a.day = b.day（且 a.day between b.start_day and b.end_day）
--   - process left join process_teg b on a.activity_id = b.activity_id and a.get_entrance_user = b.get_entrance_user
--   - final_process：left join other_scenes b on a.scene = b.scene and a.day between b.start_day and b.end_day；left join other_operate_ids c on a.operate_id = c.operate_id and a.day between c.start_day and c.end_day

-- 【注意事项】
--   - 同tmp.meishihua_activity_operate_2025_middle_1
--     
-- =====================================================


-- step1-2：创建临时的中间表1-2
<!-- drop table if exists tmp.meishihua_activity_operate_2025_middle_2 force; -->
create table tmp.meishihua_activity_operate_2025_middle_2 as 
-- scene资源位配置位,过期的资源位需要留存
with other_scenes as (
-- 1.我的tab-占位
select 'member-mytab-coursePromotion' as scene,'我的tab' as position_name,20250625 as start_day,20250831 end_day -- （注意25双11之后用operate_id参数来区分，在下方）


-- 2.搜索旁资源位-占位
union 
select 'study-learntab-homeSearchRight' as scene,'搜索旁资源位' as position_name,20250701 as start_day,20250831 end_day

)



-- operate_id资源位配置位,过期的资源位需要留存
,other_operate_ids as (
-- 1.1 商品小卡-占位
select '089dbcca-3d0d-11f0-9dc5-1f936a912c17' as operate_id,'商品小卡' as position_name,20250603 as start_day,20250930 end_day
union 
select '28bb4518-3d0d-11f0-8aae-8b6b6b8d4b94' as operate_id,'商品小卡' as position_name,20250603 as start_day,20250930 end_day
union 
select 'af1e6056-3d0b-11f0-a3ab-2bd61b67d512' as operate_id,'商品小卡' as position_name,20250603 as start_day,20250930 end_day
union 
select '53fa0dfe-42f3-11f0-90d7-a7cdeececcc5' as operate_id,'商品小卡' as position_name,20250603 as start_day,20250930 end_day
union 
select 'e4823a96-42f2-11f0-8024-fbd03b33ee14' as operate_id,'商品小卡' as position_name,20250603 as start_day,20250930 end_day
union 
select '0fdc2ac2-3d0c-11f0-ad52-e78c5e22f73b' as operate_id,'商品小卡' as position_name,20250603 as start_day,20250930 end_day
union 
select 'eb33687a-3d0b-11f0-930f-070baa95f98b' as operate_id,'商品小卡' as position_name,20250603 as start_day,20250930 end_day
union 
select '7009aed8-58be-11f0-a69a-931f458b8079' as operate_id,'商品小卡' as position_name,20250603 as start_day,20250930 end_day
union 
select '98afef00-a82d-11f0-9f10-1bafd56d460b' as operate_id,'商品小卡' as position_name,20251014 as start_day,20260113 end_day
union 
select '054ada62-a82e-11f0-8f1c-73e5981771dc' as operate_id,'商品小卡' as position_name,20251014 as start_day,20260113 end_day
union 
select '4298327a-a82e-11f0-94e1-6bb7a1b06b9b' as operate_id,'商品小卡' as position_name,20251014 as start_day,20260113 end_day
union 
select '089dbcca-3d0d-11f0-9dc5-1f936a912c17' as operate_id,'商品小卡' as position_name,20251017 as start_day,20260113 end_day
union 
select '28bb4518-3d0d-11f0-8aae-8b6b6b8d4b94' as operate_id,'商品小卡' as position_name,20251017 as start_day,20260113 end_day
union 
select 'af1e6056-3d0b-11f0-a3ab-2bd61b67d512' as operate_id,'商品小卡' as position_name,20251017 as start_day,20260113 end_day
union 
select '53fa0dfe-42f3-11f0-90d7-a7cdeececcc5' as operate_id,'商品小卡' as position_name,20251017 as start_day,20260113 end_day
union 
select 'e4823a96-42f2-11f0-8024-fbd03b33ee14' as operate_id,'商品小卡' as position_name,20251017 as start_day,20260113 end_day
union 
select '0fdc2ac2-3d0c-11f0-ad52-e78c5e22f73b' as operate_id,'商品小卡' as position_name,20251017 as start_day,20260113 end_day
union 
select 'eb33687a-3d0b-11f0-930f-070baa95f98b' as operate_id,'商品小卡' as position_name,20251017 as start_day,20260113 end_day
union 
select '7009aed8-58be-11f0-a69a-931f458b8079' as operate_id,'商品小卡' as position_name,20251017 as start_day,20260113 end_day
union 
select '8ef20ea6-eba5-11f0-9429-d34cd7baa41f' as operate_id,'商品小卡' as position_name,20260114 as start_day,20260117 end_day
union 
select 'd8f4a342-eba5-11f0-942a-1b072f6239d1' as operate_id,'商品小卡' as position_name,20260114 as start_day,20260117 end_day
union 
select 'c8262d14-eba6-11f0-942b-333ee4850dca' as operate_id,'商品小卡' as position_name,20260114 as start_day,20260117 end_day
union 
select '1d149a5e-eba7-11f0-bbae-ef62b1da0208' as operate_id,'商品小卡' as position_name,20260114 as start_day,20260117 end_day
union 
select '5ddd903c-ef98-11f0-bb6c-77f58f6e22b6' as operate_id,'商品小卡' as position_name,20260117 as start_day,20260214 end_day
union 
select '8233defa-ef98-11f0-bb6d-c73df55671f9' as operate_id,'商品小卡' as position_name,20260117 as start_day,20260214 end_day
union 
select '1e480122-ef99-11f0-bfd7-8f45b9839e50' as operate_id,'商品小卡' as position_name,20260117 as start_day,20260214 end_day
union 
select '7a70f800-ef99-11f0-a9ac-f7c5d3780416' as operate_id,'商品小卡' as position_name,20260117 as start_day,20260214 end_day
union 
select '96a55e78-0649-11f1-9feb-f3988dc930f8' as operate_id,'商品小卡' as position_name,20260215 as start_day,20260221 end_day
union 
select '55d3e26a-064a-11f1-8b7e-9354a070eb78' as operate_id,'商品小卡' as position_name,20260215 as start_day,20260221 end_day
union 
select 'c83f1810-064a-11f1-a3eb-872523570857' as operate_id,'商品小卡' as position_name,20260215 as start_day,20260221 end_day
union 
select '82779f00-0636-11f1-ae9b-2f691071424c' as operate_id,'商品小卡' as position_name,20260222 as start_day,20260301 end_day
union 
select '0c449ef4-0637-11f1-a11f-f3bf1f530510' as operate_id,'商品小卡' as position_name,20260222 as start_day,20260301 end_day
union 
select '841781d0-0637-11f1-9d35-1fb17cb1e21f' as operate_id,'商品小卡' as position_name,20260222 as start_day,20260301 end_day
union 
select '2795af80-0638-11f1-b22f-ebbcc791d14e' as operate_id,'商品小卡' as position_name,20260222 as start_day,20260301 end_day
union 
select 'b244d414-1455-11f1-9472-e33cebf9a501' as operate_id,'商品小卡' as position_name,20260302 as start_day,20260331 end_day
union 
select 'a1e577f8-1456-11f1-9200-278314c21c3a' as operate_id,'商品小卡' as position_name,20260302 as start_day,20260331 end_day
union 
select 'fe0dfa96-1456-11f1-802a-e30461191af7' as operate_id,'商品小卡' as position_name,20260302 as start_day,20260331 end_day





-- 1.2 学科专用-商品小卡-占位
union 
select '089dbcca-3d0d-11f0-9dc5-1f936a912c17' as operate_id,'学科专用-商品小卡' as position_name,20250812 as start_day,20250825 end_day
union 
select '28bb4518-3d0d-11f0-8aae-8b6b6b8d4b94' as operate_id,'学科专用-商品小卡' as position_name,20250812 as start_day,20250825 end_day
union 
select 'af1e6056-3d0b-11f0-a3ab-2bd61b67d512' as operate_id,'学科专用-商品小卡' as position_name,20250812 as start_day,20250825 end_day
union 
select '53fa0dfe-42f3-11f0-90d7-a7cdeececcc5' as operate_id,'学科专用-商品小卡' as position_name,20250812 as start_day,20250825 end_day
union 
select 'e4823a96-42f2-11f0-8024-fbd03b33ee14' as operate_id,'学科专用-商品小卡' as position_name,20250812 as start_day,20250825 end_day
union 
select '0fdc2ac2-3d0c-11f0-ad52-e78c5e22f73b' as operate_id,'学科专用-商品小卡' as position_name,20250812 as start_day,20250825 end_day
union 
select 'eb33687a-3d0b-11f0-930f-070baa95f98b' as operate_id,'学科专用-商品小卡' as position_name,20250812 as start_day,20250825 end_day
union 
select '7009aed8-58be-11f0-a69a-931f458b8079' as operate_id,'学科专用-商品小卡' as position_name,20250812 as start_day,20250825 end_day
union 
select '614a5b02-a50f-11f0-9985-f3a9e4bb402b' as operate_id,'学科专用-商品小卡' as position_name,20251010 as start_day,20251024 end_day
union 
select '614a5b02-a50f-11f0-9985-f3a9e4bb402b' as operate_id,'学科专用-商品小卡' as position_name,20251122 as start_day,20251130 end_day
union 
select 'db17e8ea-99ee-11f0-981d-e75158f2832d' as operate_id,'学科专用-商品小卡' as position_name,20251127 as start_day,20251212 end_day
union 
select '5edb34b6-c9c9-11f0-931f-4b9c6435d307' as operate_id,'学科专用-商品小卡' as position_name,20251127 as start_day,20251212 end_day
union 
select '5cba04ac-c9d1-11f0-add3-a3896e49c3e6' as operate_id,'学科专用-商品小卡' as position_name,20251127 as start_day,20251212 end_day
union 
select 'ed73cd84-c9d6-11f0-bf45-77e3d793474f' as operate_id,'学科专用-商品小卡' as position_name,20251127 as start_day,20251212 end_day
union 
select 'd79450b8-c9ce-11f0-8fd1-7774929e4c16' as operate_id,'学科专用-商品小卡' as position_name,20251127 as start_day,20251212 end_day
union 
select 'd07da832-c9cf-11f0-8500-af666d5afcf5' as operate_id,'学科专用-商品小卡' as position_name,20251127 as start_day,20251212 end_day
union 
select '7d375ce4-c9d0-11f0-82ec-7f1fe872a074' as operate_id,'学科专用-商品小卡' as position_name,20251127 as start_day,20251212 end_day


-- 2.1 学习页-NPC对话-占位
union 
select 'b926d102-8182-4503-9684-aba5c3bcd3b9' as operate_id,'学习页-NPC对话' as position_name,20250625 as start_day,20250704 end_day
union 
select 'e4f70253-d8db-4d89-bba3-d4232d80471c' as operate_id,'学习页-NPC对话' as position_name,20250705 as start_day,20250708 end_day
union 
select 'ef5c6b83-889a-43b9-b6bd-4dd3842d0d97' as operate_id,'学习页-NPC对话' as position_name,20250709 as start_day,20250710 end_day
union 
select '1a59c5a8-f8ed-4724-9687-425148bed40e' as operate_id,'学习页-NPC对话' as position_name,20250713 as start_day,20250717 end_day
union 
select '53b11ab4-01e3-4483-83e1-5a85dfea5ddd' as operate_id,'学习页-NPC对话' as position_name,20250720 as start_day,20250724 end_day
union 
select 'be52f1ef-554f-43e2-8b59-97a26b577c20' as operate_id,'学习页-NPC对话' as position_name,20250727 as start_day,20250731 end_day
union 
select '4f2ddec6-a622-4d2d-9557-e5c1f56c4bff' as operate_id,'学习页-NPC对话' as position_name,20250817 as start_day,20250821 end_day
union 
select 'f5ed717b-e2bd-4c05-b6b1-e6a5c22d81d2' as operate_id,'学习页-NPC对话' as position_name,20250824 as start_day,20250828 end_day
union 
select '87923c16-a204-47ed-80a6-d03717d24d0c' as operate_id,'学习页-NPC对话' as position_name,20250901 as start_day,20250904 end_day
union 
select '146c63fc-67d8-461e-a1da-5df5b423f6af' as operate_id,'学习页-NPC对话' as position_name,20250907 as start_day,20250907 end_day
union 
select 'efb96616-ffe3-4762-a5e6-6d2d25db3bfe' as operate_id,'学习页-NPC对话' as position_name,20250911 as start_day,20250915 end_day
union 
select 'f9eca93c-a1be-4584-a4c2-5ab5f928fab1' as operate_id,'学习页-NPC对话' as position_name,20250921 as start_day,20250926 end_day
union 
select '2a65e371-e813-49ec-a44f-bf265a601b44' as operate_id,'学习页-NPC对话' as position_name,20250927 as start_day,20250929 end_day
union 
select '336f6ef6-a4d4-42dd-9987-050cfa5839be' as operate_id,'学习页-NPC对话' as position_name,20250930 as start_day,20250930 end_day
union 
select '8d8881a5-3e90-4000-93b1-42ec24dcb450' as operate_id,'学习页-NPC对话' as position_name,20251014 as start_day,20251016 end_day
union 
select 'c90329a1-61c4-4b7d-ba42-80ab18953d66' as operate_id,'学习页-NPC对话' as position_name,20251017 as start_day,20251020 end_day
union 
select 'f3c60a85-fc04-4585-b8c6-71b75d2736b8' as operate_id,'学习页-NPC对话' as position_name,20260114 as start_day,20260117 end_day
union 
select 'acb34848-7f06-454d-877a-c0392d4360dd' as operate_id,'学习页-NPC对话' as position_name,20260114 as start_day,20260117 end_day
union 
select '84386474-f192-4346-ad95-cdabc6e7613b' as operate_id,'学习页-NPC对话' as position_name,20260117 as start_day,20260120 end_day
union 
select '76c26aea-e989-4795-ba7c-243cb207d870' as operate_id,'学习页-NPC对话' as position_name,20260117 as start_day,20260120 end_day
union 
select 'db6d68b3-4d81-4984-bb3d-ebbed1e7d93f' as operate_id,'学习页-NPC对话' as position_name,20260121 as start_day,20260122 end_day
union 
select '43e579b1-90ba-4fbd-b3e6-f0940d3ce232' as operate_id,'学习页-NPC对话' as position_name,20260123 as start_day,20260129 end_day
union 
select '16e3c2ba-5632-4d59-ba4b-42e3563a052d' as operate_id,'学习页-NPC对话' as position_name,20260130 as start_day,20260201 end_day
union 
select '8e5c3059-639b-48f8-b220-59420a8f5c9a' as operate_id,'学习页-NPC对话' as position_name,20260202 as start_day,20260205 end_day
union 
select 'f7b04f1e-b8bd-4cdd-8492-dc48ec180c98' as operate_id,'学习页-NPC对话' as position_name,20260206 as start_day,20260208 end_day
union 
select '961a36f9-7775-42b2-b267-21eda73da0f2' as operate_id,'学习页-NPC对话' as position_name,20260209 as start_day,20260209 end_day
union 
select '85eb373c-ef70-43f4-bf29-c6de7345c567' as operate_id,'学习页-NPC对话' as position_name,20260210 as start_day,20260210 end_day
union 
select '189678c7-ac6b-4a18-89f1-26a7e72f4497' as operate_id,'学习页-NPC对话' as position_name,20260211 as start_day,20260211 end_day
union 
select 'cda16587-3e2e-4615-bfac-2c3ab04f1d7c' as operate_id,'学习页-NPC对话' as position_name,20260212 as start_day,20260212 end_day
union 
select '9f66fc09-7f82-4084-8d8a-25ba33b926f6' as operate_id,'学习页-NPC对话' as position_name,20260213 as start_day,20260213 end_day
union 
select '403b5617-4190-4506-9687-bba3413a9264' as operate_id,'学习页-NPC对话' as position_name,20260214 as start_day,20260214 end_day
union 
select 'cc45010d-beda-414e-b6b3-4d157e94a532' as operate_id,'学习页-NPC对话' as position_name,20260215 as start_day,20260221 end_day
union 
select 'ce968b54-ff33-4f37-8355-8a34c58dc8fd' as operate_id,'学习页-NPC对话' as position_name,20260222 as start_day,20260226 end_day
union 
select 'cf88a82d-2e72-4784-9e1b-f421eabd1460' as operate_id,'学习页-NPC对话' as position_name,20260227 as start_day,20260301 end_day
union 
select 'b14f31d2-c923-4412-b6c6-f6af409fb6ec' as operate_id,'学习页-NPC对话' as position_name,20260227 as start_day,20260301 end_day
union 
select '305e5e7c-d96c-469b-9651-d64a4733d914' as operate_id,'学习页-NPC对话' as position_name,20260302 as start_day,20260306 end_day
union 
select '8a78e493-9d51-4e41-addc-9f23b7ba52e8' as operate_id,'学习页-NPC对话' as position_name,20260307 as start_day,20260312 end_day
union 
select '3d764999-306c-41d1-8105-ff7cc9d61bd0' as operate_id,'学习页-NPC对话' as position_name,20260313 as start_day,20260318 end_day
union 
select '415572d0-bd72-4da2-86a5-92940b2e4e47' as operate_id,'学习页-NPC对话' as position_name,20260319 as start_day,20260323 end_day
union 
select 'be844ed7-8dee-45f5-9f63-aad7d9249d38' as operate_id,'学习页-NPC对话' as position_name,20260324 as start_day,20260326 end_day
union 
select '14992289-2dcb-4496-bc85-54ff86669a1a' as operate_id,'学习页-NPC对话' as position_name,20260327 as start_day,20260331 end_day
union 
select '8caa2dfc-982b-4b1a-94bc-8e7324e3439c' as operate_id,'学习页-NPC对话' as position_name,20260327 as start_day,20260331 end_day
union 
select 'e378ca9c-a4a3-4904-92a8-dd5dfd8f2923' as operate_id,'学习页-NPC对话' as position_name,20260327 as start_day,20260331 end_day
union 
select 'd4db5eda-9925-4973-998d-d186cd13ec30' as operate_id,'学习页-NPC对话' as position_name,20260327 as start_day,20260331 end_day
union 
select 'df964562-1281-4896-864a-4db06908a5ee' as operate_id,'学习页-NPC对话' as position_name,20260327 as start_day,20260331 end_day






-- 2.2 学科专用-学习页-NPC对话-占位
union 
select '2aad4405-b28f-4d4e-85f3-90a39e7fc3a1' as operate_id,'学科专用-学习页-NPC对话' as position_name,20250812 as start_day,20250814 end_day
union 
select '99572d76-cb74-45a4-b922-13888a8d845f' as operate_id,'学科专用-学习页-NPC对话' as position_name,20251017 as start_day,20251024 end_day




-- 3.1 悬浮球-占位
union 
select 'paypage-youxia-flyball' as operate_id,'悬浮球' as position_name,20250625 as start_day,20250831 end_day


-- 3.2 学科专用-悬浮球-占位
union 
select 'paypage-youxia-flyball' as operate_id,'学科专用-悬浮球' as position_name,20250812 as start_day,20250814 end_day



-- 4.1 我的tab-占位（注意25双11之后用operate_id参数来区分）
union
select 'member-mytab-coursePromotion' as operate_id,'我的tab' as position_name,20251014 as start_day,20251111 end_day
union
select 'member-mytab-coursePromotion' as operate_id,'我的tab' as position_name,20260114 as start_day,20260301 end_day


-- 5.发现tab自动跳转-占位
union 
select 'faxian_auto' as operate_id,'发现tab自动跳转' as position_name,20251014 as start_day,20251111 end_day
union 
select 'faxian-auto' as operate_id,'发现tab自动跳转' as position_name,20260114 as start_day,20260114 end_day
union 
select 'faxian-auto' as operate_id,'发现tab自动跳转' as position_name,20260117 as start_day,20260119 end_day
union 
select 'faxian-auto' as operate_id,'发现tab自动跳转' as position_name,20260123 as start_day,20260125 end_day
union 
select 'faxian-auto' as operate_id,'发现tab自动跳转' as position_name,20260201 as start_day,20260203 end_day
union 
select 'faxian-auto' as operate_id,'发现tab自动跳转' as position_name,20260222 as start_day,20260224 end_day
union 
select 'faxian_auto' as operate_id,'发现tab自动跳转' as position_name,20260114 as start_day,20260114 end_day
union 
select 'faxian_auto' as operate_id,'发现tab自动跳转' as position_name,20260117 as start_day,20260119 end_day
union 
select 'faxian_auto' as operate_id,'发现tab自动跳转' as position_name,20260123 as start_day,20260125 end_day
union 
select 'faxian_auto' as operate_id,'发现tab自动跳转' as position_name,20260201 as start_day,20260203 end_day
union 
select 'faxian_auto' as operate_id,'发现tab自动跳转' as position_name,20260222 as start_day,20260224 end_day
)



,process_0 as (
select
       get_entrance_user
        ,operate_id
        ,scene
        ,a.day 
        ,b.activity_id
        ,b.activity_name
    ,MAX(CASE WHEN business_user_pay_status_statistics is NOT NULL THEN business_user_pay_status_statistics ELSE '未知' END) AS business_user_pay_status_statistics
    ,MAX(CASE WHEN business_user_pay_status_business is NOT NULL THEN business_user_pay_status_business ELSE '未知' END) AS business_user_pay_status_business
    ,MAX(CASE WHEN stage_name IN ('小学','初中','高中','中职') THEN grade ELSE '未知' END) AS grade_name
    ,MAX(CASE WHEN stage_name IN ('小学','初中','高中','中职') THEN stage_name ELSE '未知' END) AS stage_name
    ,MAX(CASE WHEN stage_name IN ('小学','初中','高中','中职') THEN grade_stage_name ELSE '未知' END) AS grade_stage_name
    ,SUM(CASE WHEN click_entrance_user IS NOT NULL THEN 1 ELSE 0 END) AS click_entrance_user
    ,SUM(CASE 
              WHEN b.activity_id = 8 and operate_id = 'member-mytab-coursePromotion' and page_name <> '组合课包会场' THEN 0 -- 双十一正式页面只卡我的tab这个特殊资源位进入商品页的页面名称
              WHEN enter_good_page_user IS NOT NULL THEN 1 
              ELSE 0 
              END) AS enter_good_page_user 
    ,SUM(CASE WHEN click_good_page_user IS NOT NULL THEN 1 ELSE 0 END) AS click_good_page_user
    ,SUM(CASE WHEN enter_order_page_user IS NOT NULL THEN 1 ELSE 0 END) AS enter_order_page_user
    ,SUM(CASE WHEN click_order_page_user IS NOT NULL THEN 1 ELSE 0 END) AS click_order_page_user
    ,SUM(CASE WHEN get_order_user IS NOT NULL THEN 1 ELSE 0 END) AS get_order_user
    ,SUM(CASE WHEN paid_order_user IS NOT NULL THEN 1 ELSE 0 END) AS paid_order_user
        ,SUM(CASE WHEN amount IS NOT NULL THEN amount ELSE 0 END) as amount
    from aws.business_user_pay_process_day a 
    join tmp.meishihua_activity_operate_2025_middle_1 b on a.day = b.day  
    where a.day >= b.start_day and a.day <= b.end_day 
    and a.day <= DATE_FORMAT(date_sub(current_date(), 1), '%Y%m%d')
    and get_entrance_user is not null
    group by 1,2,3,4,5,6
)




-- 用户的活动唯一标签，按活动中首次的分层和标签来分组，避免在同一场活动中被分组后重复汇总
,process_teg as (
select 
get_entrance_user
,activity_id
,activity_name
,business_user_pay_status_statistics as business_user_pay_status_statistics_activity
,business_user_pay_status_business as business_user_pay_status_business_activity
,grade_name as grade_name_activity
,stage_name as stage_name_activity
,grade_stage_name as grade_stage_name_activity
from 
(select  
       get_entrance_user
      ,activity_id
        ,activity_name
        ,business_user_pay_status_statistics
        ,business_user_pay_status_business
        ,grade_name
    ,stage_name
    ,grade_stage_name
    ,row_number() over(partition by activity_id,get_entrance_user order by day) as ranks
from process_0 
) a 
where ranks = 1 
group by 1,2,3,4,5,6,7,8
)



,process as (
select a.*
,b.business_user_pay_status_statistics_activity
,b.business_user_pay_status_business_activity
,b.grade_name_activity
,b.stage_name_activity
,b.grade_stage_name_activity
from process_0 a 
left join process_teg b on a.activity_id = b.activity_id and a.get_entrance_user = b.get_entrance_user
)



,final_process as (select a.*
,case when c.position_name is not null then c.position_name else b.position_name end as position_name
from process a 
left join other_scenes b 
on a.scene = b.scene and a.day >= b.start_day and a.day <= b.end_day
left join other_operate_ids c
on a.operate_id = c.operate_id and a.day >= c.start_day and a.day <= c.end_day
)


select * from final_process 
-- 学科活动使用专用的临时资源位
where (activity_id in (5,10,11,12 ) and position_name regexp '学科专用')
or (activity_id not in (5,10,11,12 ) and position_name not regexp '学科专用')
or position_name is null ;

-- =====================================================
-- 枚举值
-- =====================================================
--
-- 见建表sql
