# kuban_admincomp
## A ox_lib admin comp resource for FiveM QBCore Servers 💭

- Supported frameworks: ESX, QBCore & Qbox 
- Supports ox_target

Preview: [Click Here](https://www.youtube.com/watch?v=4SU52zxiX1c)
Discord: [Click Here](https://discord.com/invite/UzVbtKEzgN)
<br>

> Dependencies:
> <br>
> **[ox_lib](https://github.com/overextended/ox_lib)**

<br>

[![thumbnail](https://r2.fivemanage.com/XsqgP28FfY2PpHVl7sArP/images/COMP.png)](https://www.youtube.com/@kubanscripts)

Add this to SQL 
CREATE TABLE `kuban_comp` (
	`code` TEXT NULL DEFAULT NULL COLLATE 'utf8mb3_general_ci',
	`item` LONGTEXT NULL DEFAULT NULL COLLATE 'utf8mb3_general_ci',
	`amount` INT(11) NULL DEFAULT NULL
)
COLLATE='utf8mb3_general_ci'
ENGINE=InnoDB
;
