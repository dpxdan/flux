DROP TABLE IF EXISTS `login_activity_report`;

CREATE TABLE `login_activity_report` (
  `id` int NOT NULL AUTO_INCREMENT,
  `account_id` int NOT NULL,
  `user_agent` varchar(255) NOT NULL,
  `country_name` varchar(200) NOT NULL,
  `ip` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT '',
  `timestamp` timestamp NOT NULL,
  PRIMARY KEY (`id`),
  KEY `ip` (`ip`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO `login_activity_report` VALUES (1,1,'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/89.0.4389.114 Safari/537.36','','::1','2021-05-12 07:46:07');

DROP TABLE IF EXISTS `activity_reports`;
CREATE TABLE `activity_reports` (
  `id` int NOT NULL AUTO_INCREMENT,
  `accountid` int NOT NULL,
  `reseller_id` int NOT NULL DEFAULT '1',
  `last_did_call_time` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `last_outbound_call_time` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `balance` varchar(40) NOT NULL,
  `credit_limit` varchar(40) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `accountid` (`accountid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO `menu_modules` (`id`, `menu_label`, `module_name`, `module_url`, `menu_title`, `menu_image`, `menu_subtitle`, `priority`) VALUES(NULL, 'Activity Report', 'activity_report', 'activity_report/activityReport/', 'Reports', "Activity-Reports.png", '0', 82.1);

INSERT INTO `menu_modules` (`id`, `menu_label`, `module_name`, `module_url`, `menu_title`, `menu_image`, `menu_subtitle`, `priority`) VALUES(NULL, 'Registered SIP Devices', 'sip', 'fsmonitor/sip_devices/', 'Switch', "Live-Report.png", '0', 100.6);

INSERT INTO `roles_and_permission` (`id`, `login_type`, `permission_type`, `menu_name`, `module_name`, `sub_module_name`, `module_url`, `display_name`, `permissions`, `status`, `creation_date`, `priority`) VALUES
(NULL, 0, 0, 'reports','activity_report','0','activityReport', 'Call Activity Report', '["main","list","search","export"]', 0, '2019-01-25 09:01:03', '9.96000'); 

UPDATE userlevels SET module_permissions = concat( module_permissions, ',', (  SELECT max( id ) FROM menu_modules WHERE module_url = 'activity_report/activityReport/' ) ) WHERE userlevelid = -1;

UPDATE userlevels SET module_permissions = concat( module_permissions, ',', (  SELECT max( id ) FROM menu_modules WHERE module_url = 'fsmonitor/sip_devices/' ) ) WHERE userlevelid IN (-1, 2);


DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`fluxuser`@`localhost`*/ /*!50003 TRIGGER `activity_reports` AFTER INSERT ON `cdrs` FOR EACH ROW BEGIN
IF (NEW.calltype = 'DID' AND NEW.call_direction = 'outbound') THEN
  INSERT INTO `activity_reports` (accountid,reseller_id,last_did_call_time,balance,credit_limit) VALUES (NEW.accountid, NEW.reseller_id, NEW.callstart,(SELECT balance from accounts where id=NEW.accountid),(SELECT credit_limit from accounts where id=NEW.accountid)) ON DUPLICATE KEY UPDATE `last_did_call_time`=NEW.callstart,`balance`=VALUES(balance),`credit_limit`=VALUES(credit_limit);
ELSEIF (NEW.calltype = 'STANDARD') THEN
    INSERT INTO `activity_reports` (accountid, reseller_id,last_outbound_call_time,balance,credit_limit) VALUES (NEW.accountid, NEW.reseller_id, NEW.callstart,(SELECT balance from accounts where id=NEW.accountid),(SELECT credit_limit from accounts where id=NEW.accountid)) ON DUPLICATE KEY UPDATE `last_outbound_call_time`=NEW.callstart,`balance`=VALUES(balance),`credit_limit`=VALUES(credit_limit);
END IF;
END */;;
DELIMITER ;

alter table flux.sip_devices add column `id_sip_external` INT NOT NULL DEFAULT '0';


-- ----------------------------
-- Table structure for sip_device_routing
-- ----------------------------
DROP TABLE IF EXISTS `sip_device_routing`;
CREATE TABLE `sip_device_routing` (
  `id` int(11) NOT NULL,
  `sip_device_id` int(11) NOT NULL DEFAULT '0',
  `call_forwarding_flag` tinyint(1) NOT NULL DEFAULT '1' COMMENT '0:Enable,1:Disable',
  `call_forwarding_destination` varchar(25) DEFAULT NULL,
  `on_busy_flag` tinyint(1) NOT NULL DEFAULT '1' COMMENT '0:Enable,1:Disable',
  `on_busy_destination` varchar(25) DEFAULT NULL,
  `no_answer_flag` tinyint(1) NOT NULL DEFAULT '1' COMMENT '0:Enable,1:Disable',
  `no_answer_destination` varchar(25) DEFAULT NULL,
  `not_register_flag` tinyint(1) NOT NULL DEFAULT '1' COMMENT '0:Enable,1:Disable',
  `not_register_destination` varchar(25) DEFAULT NULL,
  `is_recording` tinyint(1) NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

ALTER TABLE `sip_device_routing`
  ADD PRIMARY KEY (`id`);

ALTER TABLE `sip_device_routing`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

INSERT INTO sip_device_routing (`sip_device_id`) SELECT `id` FROM sip_devices;


DROP TRIGGER IF EXISTS `add_sip_routing`;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`fluxuser`@`localhost`*/ /*!50003 TRIGGER `add_sip_routing` AFTER INSERT ON `sip_devices` FOR EACH ROW BEGIN
INSERT INTO sip_device_routing (`sip_device_id`) VALUES (NEW.id);
END */;;
DELIMITER ;


INSERT INTO `accounts` (`id`, `type`, `number`, `password`, `email`, `permission_id`, `first_name`, `last_name`, `telephone_1`, `telephone_2`, `notification_email`, `reseller_id`, `is_distributor`, `posttoexternal`, `local_call_cost`, `is_recording`, `notify_credit_limit`, `allow_ip_management`, `notify_flag`, `validfordays`, `expiry`, `generate_invoice`, `paypal_permission`, `notifications`, `charge_per_min`, `timezone_id`, `currency_id`, `country_id`, `deleted`, `status`, `creation`, `last_bill_date`, `credit_limit`, `balance`) VALUES ('16', '2', 'api', 'Rhbhzm8TI1YS22IskgMLLA', 'flux@flux.net.br', '3', 'API - IXC', '', '', '', 'flux@flux.net.br', '0', '1', '0', '100', '0', '5.00', '0', '0', '3650', '2033-10-29 20:11:26', '0', '1', '0', '100', '78', '16', '28', '0', '0', '2023-11-01 17:11:26', '2023-11-01 17:11:26', '0', '0');

update `system` set comment='Set Mail Log Path Here' where display_name='Mail Log';
-- Flux UPDATE-944
ALTER TABLE `trunks` ADD COLUMN `sip_cid_type` VARCHAR(50) NOT NULL COMMENT 'none:- None, rpid :- Remote-Party-ID, pid :- P-Asserted-Identity';
-- END

-- Flux UPDATE-945
  ALTER TABLE `sip_devices` ADD COLUMN `codec` varchar(100) NOT NULL DEFAULT 'PCMA,PCMU' AFTER `dir_vars`;
-- End

-- Flux UPDATE-942
update `system` set value='6.4' where name='version';
-- End

-- Flux UPDATE-975
ALTER TABLE `system` CHANGE `sub_group` `sub_group` VARCHAR(200) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
UPDATE `system` SET `sub_group`='Alert Notifications' WHERE `name` = 'alert_notications';
-- Flux UPDATE-975


-- Flux UPDATE-978
DROP TABLE IF EXISTS `automated_report_log`;
CREATE TABLE `automated_report_log` ( 
  `id` int(11) AUTO_INCREMENT primary key NOT NULL, 
  `filename` varchar(100) NULL , 
  `usercode` varchar(50)  NULL , 
  `creation_date` datetime NOT NULL,
  `purge_date` date NOT NULL
) ENGINE = InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO `system` (`id`,`name`, `display_name`, `value`, `field_type`, `comment`, `timestamp`, `reseller_id`, `is_display`, `group_title`, `sub_group`, `field_rules`) VALUES(NULL,'automated_report_attachment_deleted','Delete Automated Report Attachment After Days','1','default_system_input','Here -1 means disable and any positive value means that much of days.All attachment will delete from folder after selected time here.','0000-00-00 00:00:00',0,0,'purge','','');
-- Flux UPDATE-978

-- Flux UPDATE-1039
update menu_modules set menu_label='My Order' where module_url='user/user_products_list/';
-- End


-- Flux UPDATE-1180
ALTER TABLE automated_report_log MODIFY purge_date DATE NULL;
-- Flux UPDATE-1180

-- Flux UPDATE-1028
UPDATE default_templates SET template='<p>Dear #NAME#,</p>\n\n<p>The product #PRODUCT_NAME# has now been added to your account.</p>\n\n<p><strong>Product Information: </strong></p>\n\n<p>Product Name: #PRODUCT_NAME#<br />\nProduct Category: #PRODUCT_CATEGORY#<br />\nPayment Method: #PAYMENT_METHOD#<br />\nProduct Amount: #PRODUCT_AMOUNT#<br />\nNext Bill Date: #NEXT_BILL_DATE#<br />\nQuantity:#QUANTITY#<br />\nTotal Amount:#TOTAL_PRICE# </p>\n\n<p>You can always let us know if you have any question at #COMPANY_EMAIL#. We will be happy to help!</p>\n\n<p>Thanks,<br />\n#COMPANY_NAME#</p>\n' WHERE name='product_purchase';
-- Flux UPDATE-1028


INSERT INTO `flux`.`roles_and_permission` (`login_type`, `permission_type`, `menu_name`, `module_name`, `module_url`, `display_name`, `permissions`, `status`, `creation_date`, `priority`) VALUES ('0', '0', 'carriers', 'rates', 'termination_rates_list', 'Termination Rates', '[\"main\",\"list\",\"create\",\"edit\",\"delete\",\"search\"]', '0', '2019-01-25 09:01:03', '2.26000');
INSERT INTO `flux`.`roles_and_permission` (`menu_name`, `module_name`, `module_url`, `display_name`, `permissions`, `status`, `creation_date`, `priority`) VALUES ('carriers', 'freeswitch', 'fsgateway', 'Gateways', '[\"main\",\"list\",\"create\",\"edit\",\"delete\",\"search\"]', '0', '2019-01-25 09:01:03', '2.26000');

UPDATE `flux`.`permissions` SET `permissions` = '{\"accounts\":{\"customer_list\":{\"main\":\"0\",\"list\":\"0\",\"create\":\"0\",\"mass_create\":\"0\",\"create_provider\":\"0\",\"export\":\"0\",\"import\":\"0\",\"delete\":\"0\",\"edit\":\"0\",\"callerid\":\"0\",\"payment\":\"0\",\"search\":\"0\",\"batch_update\":\"0\"},\"reseller_list\":{\"main\":\"0\",\"list\":\"0\",\"create\":\"0\",\"export\":\"0\",\"delete\":\"0\",\"edit\":\"0\",\"search\":\"0\",\"payment\":\"0\"},\"admin_list\":{\"main\":\"0\",\"list\":\"0\",\"create_admin\":\"0\",\"delete\":\"0\",\"edit\":\"0\",\"search\":\"0\"}},\"freeswitch\":{\"fssipdevices\":{\"main\":\"0\",\"list\":\"0\",\"create\":\"0\",\"delete\":\"0\",\"edit\":\"0\",\"search\":\"0\"},\"livecall_report\":{\"main\":\"0\",\"list\":\"0\"}},\"localization\":{\"localization_list\":{\"main\":\"0\",\"list\":\"0\",\"create\":\"0\",\"delete\":\"0\",\"edit\":\"0\",\"search\":\"0\"}},\"ipmap\":{\"ipmap_detail\":{\"main\":\"0\",\"list\":\"0\",\"create\":\"0\",\"delete\":\"0\",\"edit\":\"0\",\"search\":\"0\"}},\"animap\":{\"animap_detail\":{\"main\":\"0\",\"list\":\"0\",\"create\":\"0\",\"delete\":\"0\",\"edit\":\"0\",\"search\":\"0\"}},\"permissions\":{\"permissions_list\":{\"main\":\"0\",\"list\":\"0\",\"create\":\"0\",\"delete\":\"0\",\"edit\":\"0\",\"search\":\"0\"}},\"invoices\":{\"invoice_list\":{\"main\":\"0\",\"list\":\"0\",\"download\":\"0\",\"edit\":\"0\",\"generate\":\"0\",\"search\":\"0\",\"delete\":\"0\"},\"invoice_conf_list\":{\"main\":\"0\",\"list\":\"0\"}},\"reports\":{\"refillreport\":{\"main\":\"0\",\"list\":\"0\",\"export\":\"0\",\"search\":\"0\"},\"commission_report_list\":{\"main\":\"0\",\"list\":\"0\",\"export\":\"0\",\"search\":\"0\"},\"customerReport\":{\"main\":\"0\",\"list\":\"0\",\"export\":\"0\",\"search\":\"0\"},\"resellerReport\":{\"main\":\"0\",\"list\":\"0\",\"export\":\"0\",\"search\":\"0\"},\"providerReport\":{\"main\":\"0\",\"list\":\"0\",\"export\":\"0\",\"search\":\"0\"}},\"did\":{\"did_list\":{\"main\":\"0\",\"list\":\"0\",\"create\":\"0\",\"export\":\"0\",\"import\":\"0\",\"delete\":\"0\",\"edit\":\"0\",\"forward\":\"0\",\"search\":\"0\",\"purchase\":\"0\"}},\"accessnumber\":{\"accessnumber_list\":{\"main\":\"0\",\"list\":\"0\",\"export\":\"0\",\"import\":\"0\",\"delete\":\"0\",\"edit\":\"0\",\"search\":\"0\"}},\"pricing\":{\"price_list\":{\"main\":\"0\",\"list\":\"0\",\"create\":\"0\",\"delete\":\"0\",\"edit\":\"0\",\"search\":\"0\",\"duplicate\":\"0\"}},\"rates\":{\"origination_rates_list\":{\"main\":\"0\",\"list\":\"0\",\"create\":\"0\",\"export\":\"0\",\"import\":\"0\",\"delete\":\"0\",\"edit\":\"0\",\"search\":\"0\",\"batch_update\":\"0\"}},\"products\":{\"products_list\":{\"main\":\"0\",\"list\":\"0\",\"create\":\"0\",\"assign\":\"0\",\"delete\":\"0\",\"edit\":\"0\",\"search\":\"0\"}},\"orders\":{\"orders_list\":{\"main\":\"0\",\"list\":\"0\",\"new\":\"0\",\"edit\":\"0\",\"search\":\"0\"}},\"low_balance\":{\"low_balance_list\":{\"main\":\"0\",\"list\":\"0\",\"search\":\"0\"}},\"summary\":{\"product\":{\"main\":\"0\",\"list\":\"0\",\"search\":\"0\",\"export\":\"0\"}},\"taxes\":{\"taxes_list\":{\"main\":\"0\",\"list\":\"0\",\"create\":\"0\",\"delete\":\"0\",\"edit\":\"0\",\"search\":\"0\"}},\"systems\":{\"template\":{\"main\":\"0\",\"list\":\"0\",\"edit\":\"0\",\"search\":\"0\"}}}' WHERE (`id` = '3');

UPDATE `flux`.`userlevels` SET `module_permissions` = '1,2,3,4,5,7,8,9,13,14,15,16,17,18,19,20,21,22,25,26,27,28,29,38,40,41,42,43,44,45,65,93,94,97,100,101,104,107,108,111,114,115,118,123,124,125,131,132,135,140,141,142,148,149,152,157,158,159,165,166,167,149,229,230,231,232,233,234,235,236,237,238,275,276,306,307,376,377,390,391,506,507,578,579,580,581,582,583,592,593,626,627,91,92,561,153,154,155,150,200,151,89,556,559,563' WHERE (`userlevelid` = '2');

INSERT INTO `flux`.`permissions_types` (`permission_type_code`, `permission_name`, `reseller_id`, `status`) VALUES ('0', 'Super Admin', '0', '0');
INSERT INTO `flux`.`permissions_types` (`permission_type_code`, `permission_name`, `reseller_id`, `status`) VALUES ('1', 'Reseller', '0', '0');
INSERT INTO `flux`.`permissions_types` (`permission_type_code`, `permission_name`, `reseller_id`, `status`) VALUES ('2', 'Admin', '0', '0');
INSERT INTO `flux`.`permissions_types` (`permission_type_code`, `permission_name`, `reseller_id`, `status`) VALUES ('4', 'SubAdmin', '0', '0');

DELETE FROM `flux`.`menu_modules` WHERE (`id` = '79');
DELETE FROM `flux`.`menu_modules` WHERE (`id` = '559');
DELETE FROM `flux`.`menu_modules` WHERE (`id` = '151');
DELETE FROM `flux`.`menu_modules` WHERE (`id` = '66');
DELETE FROM `flux`.`menu_modules` WHERE (`id` = '550');
DELETE FROM `flux`.`menu_modules` WHERE (`id` = '27');

DELETE FROM `flux`.`menu_modules` WHERE (`id` = '555');
DELETE FROM `flux`.`menu_modules` WHERE (`id` = '398');
DELETE FROM `flux`.`menu_modules` WHERE (`id` = '397');
DELETE FROM `flux`.`menu_modules` WHERE (`id` = '33');
DELETE FROM `flux`.`menu_modules` WHERE (`id` = '11');
