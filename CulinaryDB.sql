
USE master
GO

IF EXISTS (SELECT 1 FROM sys.databases WHERE name = N'Culinary')
BEGIN
    ALTER DATABASE Culinary SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE Culinary;
END;
GO

CREATE DATABASE Culinary;
GO

USE Culinary;
GO

-- СОЗДАНИЕ ТАБЛИЦ УЗЛОВ (NODE TABLES)
-- Таблица узлов: Recipe (Рецепты)
-- cuisine: белорусская | русская | итальянская | французская | венгерская | японская
-- difficulty: лёгкая | средняя | сложная

CREATE TABLE [dbo].[Recipe]
(
    [id]            Int             NOT NULL,
    [name]          Nvarchar(100)   COLLATE Cyrillic_General_CI_AS NOT NULL,
    [cuisine]       Nvarchar(30)    COLLATE Cyrillic_General_CI_AS NOT NULL
                    CHECK ([cuisine] IN (N'белорусская', N'русская', N'итальянская',
                                         N'французская', N'венгерская', N'японская')),
    [difficulty]    Nvarchar(10)    COLLATE Cyrillic_General_CI_AS NOT NULL
                    CHECK ([difficulty] IN (N'лёгкая', N'средняя', N'сложная')),
    [cook_time_min] Int             NOT NULL,
    [servings]      Int             NOT NULL,
    [calories_per_serving] Decimal(7,2) NOT NULL,
    [description]   Nvarchar(300)   COLLATE Cyrillic_General_CI_AS NOT NULL
)
AS NODE
ON [PRIMARY]
GO

ALTER TABLE [dbo].[Recipe] ADD CONSTRAINT [PK_Recipe] PRIMARY KEY ([id])
ON [PRIMARY]
GO

-- Таблица узлов: Ingredient (Ингредиенты)
-- category: мясо | рыба | овощ | молочное | зерновое | специя | яйцо | жир | сладкое | зелень

CREATE TABLE [dbo].[Ingredient]
(
    [id]            Int             NOT NULL,
    [name]          Nvarchar(80)    COLLATE Cyrillic_General_CI_AS NOT NULL,
    [category]      Nvarchar(20)    COLLATE Cyrillic_General_CI_AS NOT NULL
                    CHECK ([category] IN (N'мясо', N'рыба', N'овощ', N'молочное',
                                          N'зерновое', N'специя', N'яйцо', N'жир',
                                          N'сладкое', N'зелень')),
    [unit]          Nvarchar(20)    COLLATE Cyrillic_General_CI_AS NOT NULL,
    [calories_per_100g] Decimal(6,2) NOT NULL,
    [is_allergen]   Bit             DEFAULT ((0)) NOT NULL,
    [storage_days]  Int             NOT NULL
)
AS NODE
ON [PRIMARY]
GO

ALTER TABLE [dbo].[Ingredient] ADD CONSTRAINT [PK_Ingredient] PRIMARY KEY ([id])
ON [PRIMARY]
GO

-- Таблица узлов: Technique (Кулинарные техники)
-- technique_type: термическая | нарезка | смешивание | консервация | формовка

CREATE TABLE [dbo].[Technique]
(
    [id]                Int             NOT NULL,
    [name]              Nvarchar(80)    COLLATE Cyrillic_General_CI_AS NOT NULL,
    [technique_type]    Nvarchar(20)    COLLATE Cyrillic_General_CI_AS NOT NULL
                        CHECK ([technique_type] IN (N'термическая', N'нарезка',
                                                    N'смешивание', N'консервация', N'формовка')),
    [description]       Nvarchar(300)   COLLATE Cyrillic_General_CI_AS NOT NULL,
    [avg_duration_min]  Int             NOT NULL,
    [requires_equipment] Nvarchar(100)  COLLATE Cyrillic_General_CI_AS NOT NULL
)
AS NODE
ON [PRIMARY]
GO

ALTER TABLE [dbo].[Technique] ADD CONSTRAINT [PK_Technique] PRIMARY KEY ([id])
ON [PRIMARY]
GO

-- Таблица узлов: Chef (Повара / авторы рецептов)
-- specialization: национальная | кондитерская | мясо | вегетарианская | фьюжн
-- level: домашний | профессионал | мастер

CREATE TABLE [dbo].[Chef]
(
    [id]                Int             NOT NULL,
    [name]              Nvarchar(80)    COLLATE Cyrillic_General_CI_AS NOT NULL,
    [country]           Nvarchar(50)    COLLATE Cyrillic_General_CI_AS NOT NULL,
    [specialization]    Nvarchar(20)    COLLATE Cyrillic_General_CI_AS NOT NULL
                        CHECK ([specialization] IN (N'национальная', N'кондитерская', N'мясо',
                                                    N'вегетарианская', N'фьюжн')),
    [level]             Nvarchar(15)    COLLATE Cyrillic_General_CI_AS NOT NULL
                        CHECK ([level] IN (N'домашний', N'профессионал', N'мастер')),
    [experience_years]  Int             NOT NULL,
    [michelin_stars]    Int             DEFAULT ((0)) NOT NULL
)
AS NODE
ON [PRIMARY]
GO

ALTER TABLE [dbo].[Chef] ADD CONSTRAINT [PK_Chef] PRIMARY KEY ([id])
ON [PRIMARY]
GO

-- СОЗДАНИЕ ТАБЛИЦ РЁБЕР (EDGE TABLES)
-- Ребро: RecipeIngredient (Recipe -> Ingredient)
-- Рецепт содержит ингредиент.
-- is_optional: 0 = обязательный, 1 = необязательный

CREATE TABLE [dbo].[RecipeIngredient]
(
    [quantity]      Decimal(8,2)    NOT NULL,
    [unit]          Nvarchar(20)    COLLATE Cyrillic_General_CI_AS NOT NULL,
    [is_optional]   Bit             DEFAULT ((0)) NOT NULL,
    [note]          Nvarchar(150)   COLLATE Cyrillic_General_CI_AS NULL
)
AS EDGE
ON [PRIMARY]
GO

ALTER TABLE [dbo].[RecipeIngredient] ADD CONSTRAINT [EC_RecipeIngredient] CONNECTION (
    [Recipe] TO [Ingredient])
GO

-- Ребро: AppliedIn (Technique -> Recipe)
-- Техника применяется в рецепте.
-- step_number: порядковый номер шага

CREATE TABLE [dbo].[AppliedIn]
(
    [step_number]   Int             NOT NULL,
    [duration_min]  Int             NOT NULL,
    [temperature_c] Int             NULL,
    [notes]         Nvarchar(200)   COLLATE Cyrillic_General_CI_AS NULL
)
AS EDGE
ON [PRIMARY]
GO

ALTER TABLE [dbo].[AppliedIn] ADD CONSTRAINT [EC_AppliedIn] CONNECTION (
    [Technique] TO [Recipe])
GO

-- Ребро: CanReplace (Ingredient -> Ingredient)
-- Ингредиент может заменить другой ингредиент.
-- Направленное: A -> B означает «A можно заменить на B»
-- quality_loss: без потерь | минимальная | умеренная | значительная

CREATE TABLE [dbo].[CanReplace]
(
    [quality_loss]      Nvarchar(20)    COLLATE Cyrillic_General_CI_AS NOT NULL
                        CHECK ([quality_loss] IN (N'без потерь', N'минимальная',
                                                   N'умеренная', N'значительная')),
    [ratio]             Nvarchar(50)    COLLATE Cyrillic_General_CI_AS NOT NULL,
    [verified_date]     Date            NOT NULL,
    [comment]           Nvarchar(200)   COLLATE Cyrillic_General_CI_AS NULL
)
AS EDGE
ON [PRIMARY]
GO

ALTER TABLE [dbo].[CanReplace] ADD CONSTRAINT [EC_CanReplace] CONNECTION (
    [Ingredient] TO [Ingredient])
GO

-- Ребро: UsedBy (Recipe -> Chef)
-- Рецепт используется / приготовлен поваром.
-- is_signature: 1 = фирменное блюдо

CREATE TABLE [dbo].[UsedBy]
(
    [since_year]    Int             NOT NULL,
    [is_signature]  Bit             DEFAULT ((0)) NOT NULL,
    [rating]        Decimal(3,1)    NOT NULL
                    CHECK ([rating] >= 1 AND [rating] <= 10),
    [comment]       Nvarchar(200)   COLLATE Cyrillic_General_CI_AS NULL
)
AS EDGE
ON [PRIMARY]
GO

ALTER TABLE [dbo].[UsedBy] ADD CONSTRAINT [EC_UsedBy] CONNECTION (
    [Recipe] TO [Chef])
GO

-- ЧАСТЬ 3: ЗАПОЛНЕНИЕ ТАБЛИЦ УЗЛОВ
-- 3.1 Данные: Recipe (12 рецептов)

INSERT INTO Recipe (id, name, cuisine, difficulty, cook_time_min, servings, calories_per_serving, description)
VALUES
    (1,  N'Борщ',                          N'белорусская', N'средняя', 90,  6, 280.00,
         N'Наваристый свекольный суп с мясом и капустой, символ белорусской и русской кухни'),
    (2,  N'Драники',                        N'белорусская', N'лёгкая',   40,  4, 320.00,
         N'Белорусские картофельные оладьи, жаренные на сковороде до золотистой корочки'),
    (3,  N'Пельмени',                       N'русская',    N'средняя', 80,  4, 350.00,
         N'Русские пельмени из тонкого теста с сочной мясной начинкой'),
    (4,  N'Оливье',                         N'русская',    N'лёгкая',   60,  8, 240.00,
         N'Классический русский салат с варёными овощами, яйцами, колбасой и майонезом'),
    (5,  N'Холодник',                       N'белорусская', N'лёгкая',   30,  4, 120.00,
         N'Белорусский холодный свекольный суп на кефире с огурцами и зеленью'),
    (6,  N'Мачанка с блинами',              N'белорусская', N'средняя', 100, 4, 510.00,
         N'Белорусский соус из свинины и колбасы, подаётся с тонкими блинами'),
    (7,  N'Гуляш',                          N'венгерская',  N'средняя', 110, 5, 380.00,
         N'Венгерское мясное рагу с паприкой и луком, наваристое и ароматное'),
    (8,  N'Омлет французский',              N'французская',     N'лёгкая',   15,  2, 210.00,
         N'Классический французский омлет — нежный, свёрнутый в рулет, без поджаристой корочки'),
    (9,  N'Оладьи',                         N'русская',    N'лёгкая',   30,  4, 290.00,
         N'Пышные оладьи на кефире, румяные снаружи и мягкие внутри'),
    (10, N'Крем-брюле',                     N'французская',     N'сложная',   90,  4, 430.00,
         N'Французский десерт из запечённого заварного крема с карамельной корочкой'),
    (11, N'Спагетти болоньезе',             N'итальянская',    N'средняя', 75,  4, 420.00,
         N'Итальянская паста с насыщенным соусом из фарша, томатов и красного вина'),
    (12, N'Блины',                          N'русская',    N'лёгкая',   50,  5, 260.00,
         N'Тонкие русские блины на молоке, золотистые, подаются со сметаной или вареньем');
GO


-- 3.2 Данные: Ingredient (15 ингредиентов)

INSERT INTO Ingredient (id, name, category, unit, calories_per_100g, is_allergen, storage_days)
VALUES
    (1,  N'Свёкла',             N'овощ', N'кг',    43.00,  0, 30),
    (2,  N'Картофель',          N'овощ', N'кг',    77.00,  0, 60),
    (3,  N'Говядина',           N'мясо',      N'кг',   187.00,  0, 3),
    (4,  N'Свинина',            N'мясо',      N'кг',   263.00,  0, 3),
    (5,  N'Куриный фарш',       N'мясо',      N'кг',   143.00,  0, 2),
    (6,  N'Капуста белокочанная', N'овощ', N'кг',  27.00,  0, 45),
    (7,  N'Яйцо куриное',       N'яйцо',       N'шт',  155.00,  1, 25),
    (8,  N'Молоко',             N'молочное',     N'л',    61.00,  1, 5),
    (9,  N'Сметана',            N'молочное',     N'г',   206.00,  1, 7),
    (10, N'Мука пшеничная',     N'зерновое',     N'кг',  364.00,  1, 180),
    (11, N'Лук репчатый',       N'овощ', N'кг',   41.00,  0, 30),
    (12, N'Морковь',            N'овощ', N'кг',   41.00,  0, 30),
    (13, N'Паприка сладкая',    N'специя',     N'г',   289.00,  0, 730),
    (14, N'Томатная паста',     N'овощ', N'г',    82.00,  0, 3),
    (15, N'Сливочное масло',    N'жир',       N'г',   748.00,  1, 30),
    (16, N'Кефир',              N'молочное',     N'л',    56.00,  1, 7),
    (17, N'Сахар',              N'сладкое',     N'г',   387.00,  0, 730),
    (18, N'Жирные сливки 33%',  N'молочное',     N'л',   337.00,  1, 5),
    (19, N'Укроп',              N'зелень',      N'г',    38.00,  0, 5),
    (20, N'Фарш говяжий',       N'мясо',      N'кг',  235.00,  0, 2);
GO


-- 3.3 Данные: Technique (10 техник)

INSERT INTO Technique (id, name, technique_type, description, avg_duration_min, requires_equipment)
VALUES
    (1,  N'Варка',              N'термическая',       N'Приготовление продуктов в кипящей воде или бульоне', 30, N'Кастрюля, плита'),
    (2,  N'Жарка на сковороде', N'термическая',       N'Приготовление продуктов на раскалённой сковороде с маслом', 15, N'Сковорода, плита'),
    (3,  N'Тушение',            N'термическая',       N'Медленное томление продуктов в небольшом количестве жидкости под крышкой', 60, N'Кастрюля, плита'),
    (4,  N'Запекание в духовке',N'термическая',       N'Приготовление продуктов в горячей духовке без жидкости', 40, N'Духовой шкаф, форма для запекания'),
    (5,  N'Натирание на тёрке', N'нарезка',       N'Измельчение продуктов с помощью тёрки', 10, N'Тёрка'),
    (6,  N'Замес теста',        N'смешивание',        N'Соединение ингредиентов в однородное тесто', 15, N'Миска, руки или миксер'),
    (7,  N'Перемешивание',      N'смешивание',        N'Соединение продуктов до однородности', 5,  N'Ложка или венчик'),
    (8,  N'Карамелизация',      N'термическая',       N'Нагрев сахара до образования янтарной карамели', 10, N'Горелка или гриль'),
    (9,  N'Взбивание',          N'смешивание',        N'Насыщение продукта воздухом с помощью венчика или миксера', 10, N'Миксер или венчик'),
    (10, N'Лепка',              N'формовка',       N'Формирование изделий из теста вручную', 30, N'Руки, доска, скалка');
GO


-- 3.4 Данные: Chef (10 поваров)

INSERT INTO Chef (id, name, country, specialization, level, experience_years, michelin_stars)
VALUES
    (1,  N'Алексей Дудченко',       N'Беларусь',  N'национальная',    N'профессионал', 18, 0),
    (2,  N'Татьяна Маслова',        N'Россия',    N'национальная',    N'мастер',       25, 1),
    (3,  N'Иван Назаров',           N'Россия',    N'мясо',        N'профессионал', 12, 0),
    (4,  N'Людмила Ковалёва',       N'Беларусь',  N'национальная',    N'домашний',          8, 0),
    (5,  N'Жан-Пьер Дюбуа',        N'Франция',   N'кондитерская',      N'мастер',       30, 2),
    (6,  N'Андраш Варга',           N'Венгрия',   N'мясо',        N'профессионал', 20, 0),
    (7,  N'Марко Феррари',          N'Италия',    N'национальная',    N'мастер',       22, 1),
    (8,  N'Светлана Орлова',        N'Россия',    N'вегетарианская',  N'профессионал', 10, 0),
    (9,  N'Виктор Зайцев',          N'Россия',    N'национальная',    N'домашний',          5, 0),
    (10, N'Мария Жукова',           N'Беларусь',  N'кондитерская',      N'профессионал', 15, 0);
GO


-- ЧАСТЬ 4: ЗАПОЛНЕНИЕ ТАБЛИЦ РЁБЕР
-- 4.1 RecipeIngredient: Рецепт → Ингредиент

INSERT INTO RecipeIngredient ($from_id, $to_id, quantity, unit, is_optional, note)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 1),
     (SELECT $node_id FROM Ingredient WHERE id = 1), 0.50, N'кг', 0, N'Натереть или нарезать соломкой');
INSERT INTO RecipeIngredient ($from_id, $to_id, quantity, unit, is_optional, note)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 1),
     (SELECT $node_id FROM Ingredient WHERE id = 3), 0.50, N'кг', 0, N'На кости для бульона');
INSERT INTO RecipeIngredient ($from_id, $to_id, quantity, unit, is_optional, note)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 1),
     (SELECT $node_id FROM Ingredient WHERE id = 6), 0.30, N'кг', 0, NULL);
INSERT INTO RecipeIngredient ($from_id, $to_id, quantity, unit, is_optional, note)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 1),
     (SELECT $node_id FROM Ingredient WHERE id = 2), 0.30, N'кг', 0, NULL);
INSERT INTO RecipeIngredient ($from_id, $to_id, quantity, unit, is_optional, note)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 1),
     (SELECT $node_id FROM Ingredient WHERE id = 12), 0.15, N'кг', 0, NULL);
INSERT INTO RecipeIngredient ($from_id, $to_id, quantity, unit, is_optional, note)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 1),
     (SELECT $node_id FROM Ingredient WHERE id = 11), 0.10, N'кг', 0, NULL);
INSERT INTO RecipeIngredient ($from_id, $to_id, quantity, unit, is_optional, note)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 1),
     (SELECT $node_id FROM Ingredient WHERE id = 9), 100.00, N'г', 1, N'Подавать отдельно');
INSERT INTO RecipeIngredient ($from_id, $to_id, quantity, unit, is_optional, note)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 2),
     (SELECT $node_id FROM Ingredient WHERE id = 2), 0.80, N'кг', 0, N'Натереть на мелкой тёрке');
INSERT INTO RecipeIngredient ($from_id, $to_id, quantity, unit, is_optional, note)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 2),
     (SELECT $node_id FROM Ingredient WHERE id = 7), 2.00, N'шт', 0, NULL);
INSERT INTO RecipeIngredient ($from_id, $to_id, quantity, unit, is_optional, note)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 2),
     (SELECT $node_id FROM Ingredient WHERE id = 10), 30.00, N'г',  0, NULL);
INSERT INTO RecipeIngredient ($from_id, $to_id, quantity, unit, is_optional, note)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 2),
     (SELECT $node_id FROM Ingredient WHERE id = 11), 0.10, N'кг', 1, N'По желанию');
INSERT INTO RecipeIngredient ($from_id, $to_id, quantity, unit, is_optional, note)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 2),
     (SELECT $node_id FROM Ingredient WHERE id = 9), 100.00, N'г', 1, N'Подавать отдельно');
INSERT INTO RecipeIngredient ($from_id, $to_id, quantity, unit, is_optional, note)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 3),
     (SELECT $node_id FROM Ingredient WHERE id = 10), 0.50, N'кг', 0, N'Для теста');
INSERT INTO RecipeIngredient ($from_id, $to_id, quantity, unit, is_optional, note)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 3),
     (SELECT $node_id FROM Ingredient WHERE id = 7), 1.00, N'шт', 0, N'Для теста');
INSERT INTO RecipeIngredient ($from_id, $to_id, quantity, unit, is_optional, note)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 3),
     (SELECT $node_id FROM Ingredient WHERE id = 4), 0.40, N'кг', 0, N'Свинина + говядина 50/50');
INSERT INTO RecipeIngredient ($from_id, $to_id, quantity, unit, is_optional, note)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 3),
     (SELECT $node_id FROM Ingredient WHERE id = 3), 0.20, N'кг', 0, N'Свинина + говядина 50/50');
INSERT INTO RecipeIngredient ($from_id, $to_id, quantity, unit, is_optional, note)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 3),
     (SELECT $node_id FROM Ingredient WHERE id = 11), 0.10, N'кг', 0, NULL);
INSERT INTO RecipeIngredient ($from_id, $to_id, quantity, unit, is_optional, note)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 4),
     (SELECT $node_id FROM Ingredient WHERE id = 2), 0.40, N'кг', 0, N'Отварить');
INSERT INTO RecipeIngredient ($from_id, $to_id, quantity, unit, is_optional, note)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 4),
     (SELECT $node_id FROM Ingredient WHERE id = 7), 4.00, N'шт', 0, N'Отварить');
INSERT INTO RecipeIngredient ($from_id, $to_id, quantity, unit, is_optional, note)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 4),
     (SELECT $node_id FROM Ingredient WHERE id = 12), 0.20, N'кг', 0, N'Отварить');
INSERT INTO RecipeIngredient ($from_id, $to_id, quantity, unit, is_optional, note)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 4),
     (SELECT $node_id FROM Ingredient WHERE id = 4), 0.30, N'кг', 0, N'Варёная колбаса');
INSERT INTO RecipeIngredient ($from_id, $to_id, quantity, unit, is_optional, note)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 4),
     (SELECT $node_id FROM Ingredient WHERE id = 9), 150.00, N'г', 0, NULL);
INSERT INTO RecipeIngredient ($from_id, $to_id, quantity, unit, is_optional, note)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 5),
     (SELECT $node_id FROM Ingredient WHERE id = 1), 0.30, N'кг', 0, N'Отварить и натереть');
INSERT INTO RecipeIngredient ($from_id, $to_id, quantity, unit, is_optional, note)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 5),
     (SELECT $node_id FROM Ingredient WHERE id = 16), 0.50, N'л', 0, NULL);
INSERT INTO RecipeIngredient ($from_id, $to_id, quantity, unit, is_optional, note)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 5),
     (SELECT $node_id FROM Ingredient WHERE id = 7), 2.00, N'шт', 0, N'Отварить');
INSERT INTO RecipeIngredient ($from_id, $to_id, quantity, unit, is_optional, note)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 5),
     (SELECT $node_id FROM Ingredient WHERE id = 19), 20.00, N'г', 0, NULL);
INSERT INTO RecipeIngredient ($from_id, $to_id, quantity, unit, is_optional, note)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 5),
     (SELECT $node_id FROM Ingredient WHERE id = 9), 50.00, N'г', 1, NULL);
INSERT INTO RecipeIngredient ($from_id, $to_id, quantity, unit, is_optional, note)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 6),
     (SELECT $node_id FROM Ingredient WHERE id = 4), 0.60, N'кг', 0, N'Ребра и грудинка');
INSERT INTO RecipeIngredient ($from_id, $to_id, quantity, unit, is_optional, note)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 6),
     (SELECT $node_id FROM Ingredient WHERE id = 11), 0.15, N'кг', 0, NULL);
INSERT INTO RecipeIngredient ($from_id, $to_id, quantity, unit, is_optional, note)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 6),
     (SELECT $node_id FROM Ingredient WHERE id = 10), 0.30, N'кг', 0, N'Для блинов');
INSERT INTO RecipeIngredient ($from_id, $to_id, quantity, unit, is_optional, note)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 6),
     (SELECT $node_id FROM Ingredient WHERE id = 8), 0.50, N'л', 0, N'Для блинов');
INSERT INTO RecipeIngredient ($from_id, $to_id, quantity, unit, is_optional, note)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 6),
     (SELECT $node_id FROM Ingredient WHERE id = 7), 3.00, N'шт', 0, N'Для блинов');
INSERT INTO RecipeIngredient ($from_id, $to_id, quantity, unit, is_optional, note)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 7),
     (SELECT $node_id FROM Ingredient WHERE id = 3), 0.80, N'кг', 0, N'Нарезать кубиками');
INSERT INTO RecipeIngredient ($from_id, $to_id, quantity, unit, is_optional, note)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 7),
     (SELECT $node_id FROM Ingredient WHERE id = 11), 0.30, N'кг', 0, NULL);
INSERT INTO RecipeIngredient ($from_id, $to_id, quantity, unit, is_optional, note)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 7),
     (SELECT $node_id FROM Ingredient WHERE id = 13), 20.00, N'г', 0, N'Ключевая специя');
INSERT INTO RecipeIngredient ($from_id, $to_id, quantity, unit, is_optional, note)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 7),
     (SELECT $node_id FROM Ingredient WHERE id = 14), 80.00, N'г', 0, NULL);
INSERT INTO RecipeIngredient ($from_id, $to_id, quantity, unit, is_optional, note)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 7),
     (SELECT $node_id FROM Ingredient WHERE id = 12), 0.20, N'кг', 1, NULL);
INSERT INTO RecipeIngredient ($from_id, $to_id, quantity, unit, is_optional, note)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 8),
     (SELECT $node_id FROM Ingredient WHERE id = 7), 3.00, N'шт', 0, NULL);
INSERT INTO RecipeIngredient ($from_id, $to_id, quantity, unit, is_optional, note)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 8),
     (SELECT $node_id FROM Ingredient WHERE id = 8), 30.00, N'мл', 1, N'Можно без молока');
INSERT INTO RecipeIngredient ($from_id, $to_id, quantity, unit, is_optional, note)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 8),
     (SELECT $node_id FROM Ingredient WHERE id = 15), 15.00, N'г', 0, N'Для жарки');
INSERT INTO RecipeIngredient ($from_id, $to_id, quantity, unit, is_optional, note)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 9),
     (SELECT $node_id FROM Ingredient WHERE id = 16), 0.25, N'л', 0, NULL);
INSERT INTO RecipeIngredient ($from_id, $to_id, quantity, unit, is_optional, note)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 9),
     (SELECT $node_id FROM Ingredient WHERE id = 10), 0.20, N'кг', 0, NULL);
INSERT INTO RecipeIngredient ($from_id, $to_id, quantity, unit, is_optional, note)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 9),
     (SELECT $node_id FROM Ingredient WHERE id = 7), 1.00, N'шт', 0, NULL);
INSERT INTO RecipeIngredient ($from_id, $to_id, quantity, unit, is_optional, note)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 9),
     (SELECT $node_id FROM Ingredient WHERE id = 17), 20.00, N'г', 0, NULL);
INSERT INTO RecipeIngredient ($from_id, $to_id, quantity, unit, is_optional, note)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 9),
     (SELECT $node_id FROM Ingredient WHERE id = 9), 50.00, N'г', 1, N'Подавать отдельно');
INSERT INTO RecipeIngredient ($from_id, $to_id, quantity, unit, is_optional, note)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 10),
     (SELECT $node_id FROM Ingredient WHERE id = 18), 0.50, N'л', 0, N'Жирные сливки 33%');
INSERT INTO RecipeIngredient ($from_id, $to_id, quantity, unit, is_optional, note)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 10),
     (SELECT $node_id FROM Ingredient WHERE id = 7), 6.00, N'шт', 0, N'Только желтки');
INSERT INTO RecipeIngredient ($from_id, $to_id, quantity, unit, is_optional, note)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 10),
     (SELECT $node_id FROM Ingredient WHERE id = 17), 100.00, N'г', 0, N'Часть для карамели');
INSERT INTO RecipeIngredient ($from_id, $to_id, quantity, unit, is_optional, note)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 11),
     (SELECT $node_id FROM Ingredient WHERE id = 20), 0.50, N'кг', 0, NULL);
INSERT INTO RecipeIngredient ($from_id, $to_id, quantity, unit, is_optional, note)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 11),
     (SELECT $node_id FROM Ingredient WHERE id = 14), 120.00, N'г', 0, NULL);
INSERT INTO RecipeIngredient ($from_id, $to_id, quantity, unit, is_optional, note)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 11),
     (SELECT $node_id FROM Ingredient WHERE id = 11), 0.15, N'кг', 0, NULL);
INSERT INTO RecipeIngredient ($from_id, $to_id, quantity, unit, is_optional, note)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 11),
     (SELECT $node_id FROM Ingredient WHERE id = 12), 0.10, N'кг', 0, NULL);
INSERT INTO RecipeIngredient ($from_id, $to_id, quantity, unit, is_optional, note)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 11),
     (SELECT $node_id FROM Ingredient WHERE id = 10), 0.40, N'кг', 0, N'Спагетти или другая паста');
INSERT INTO RecipeIngredient ($from_id, $to_id, quantity, unit, is_optional, note)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 12),
     (SELECT $node_id FROM Ingredient WHERE id = 10), 0.30, N'кг', 0, NULL);
INSERT INTO RecipeIngredient ($from_id, $to_id, quantity, unit, is_optional, note)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 12),
     (SELECT $node_id FROM Ingredient WHERE id = 8), 0.50, N'л', 0, NULL);
INSERT INTO RecipeIngredient ($from_id, $to_id, quantity, unit, is_optional, note)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 12),
     (SELECT $node_id FROM Ingredient WHERE id = 7), 2.00, N'шт', 0, NULL);
INSERT INTO RecipeIngredient ($from_id, $to_id, quantity, unit, is_optional, note)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 12),
     (SELECT $node_id FROM Ingredient WHERE id = 17), 15.00, N'г', 0, NULL);
INSERT INTO RecipeIngredient ($from_id, $to_id, quantity, unit, is_optional, note)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 12),
     (SELECT $node_id FROM Ingredient WHERE id = 15), 20.00, N'г', 0, N'Для смазывания сковороды');
GO


-- 4.2 AppliedIn: Техника → Рецепт

INSERT INTO AppliedIn ($from_id, $to_id, step_number, duration_min, temperature_c, notes)
VALUES
    ((SELECT $node_id FROM Technique WHERE id = 1),
     (SELECT $node_id FROM Recipe WHERE id = 1), 1, 60, 100, N'Варить говядину до мягкости');
INSERT INTO AppliedIn ($from_id, $to_id, step_number, duration_min, temperature_c, notes)
VALUES
    ((SELECT $node_id FROM Technique WHERE id = 3),
     (SELECT $node_id FROM Recipe WHERE id = 1), 2, 25, 90,  N'Тушить овощи с томатом');
INSERT INTO AppliedIn ($from_id, $to_id, step_number, duration_min, temperature_c, notes)
VALUES
    ((SELECT $node_id FROM Technique WHERE id = 5),
     (SELECT $node_id FROM Recipe WHERE id = 1), 3, 5,  NULL, N'Натереть свёклу');
INSERT INTO AppliedIn ($from_id, $to_id, step_number, duration_min, temperature_c, notes)
VALUES
    ((SELECT $node_id FROM Technique WHERE id = 5),
     (SELECT $node_id FROM Recipe WHERE id = 2), 1, 10, NULL, N'Натереть картофель на мелкой тёрке');
INSERT INTO AppliedIn ($from_id, $to_id, step_number, duration_min, temperature_c, notes)
VALUES
    ((SELECT $node_id FROM Technique WHERE id = 2),
     (SELECT $node_id FROM Recipe WHERE id = 2), 2, 20, 170, N'Жарить по 3 мин с каждой стороны');
INSERT INTO AppliedIn ($from_id, $to_id, step_number, duration_min, temperature_c, notes)
VALUES
    ((SELECT $node_id FROM Technique WHERE id = 6),
     (SELECT $node_id FROM Recipe WHERE id = 3), 1, 15, NULL, N'Замесить крутое тесто');
INSERT INTO AppliedIn ($from_id, $to_id, step_number, duration_min, temperature_c, notes)
VALUES
    ((SELECT $node_id FROM Technique WHERE id = 10),
     (SELECT $node_id FROM Recipe WHERE id = 3), 2, 30, NULL, N'Лепить пельмени');
INSERT INTO AppliedIn ($from_id, $to_id, step_number, duration_min, temperature_c, notes)
VALUES
    ((SELECT $node_id FROM Technique WHERE id = 1),
     (SELECT $node_id FROM Recipe WHERE id = 3), 3, 10, 100, N'Варить в подсоленной воде 7-10 минут');
INSERT INTO AppliedIn ($from_id, $to_id, step_number, duration_min, temperature_c, notes)
VALUES
    ((SELECT $node_id FROM Technique WHERE id = 1),
     (SELECT $node_id FROM Recipe WHERE id = 4), 1, 30, 100, N'Отварить овощи и яйца');
INSERT INTO AppliedIn ($from_id, $to_id, step_number, duration_min, temperature_c, notes)
VALUES
    ((SELECT $node_id FROM Technique WHERE id = 7),
     (SELECT $node_id FROM Recipe WHERE id = 4), 2, 10, NULL, N'Нарезать и перемешать всё с майонезом');
INSERT INTO AppliedIn ($from_id, $to_id, step_number, duration_min, temperature_c, notes)
VALUES
    ((SELECT $node_id FROM Technique WHERE id = 1),
     (SELECT $node_id FROM Recipe WHERE id = 5), 1, 25, 100, N'Отварить свёклу и яйца');
INSERT INTO AppliedIn ($from_id, $to_id, step_number, duration_min, temperature_c, notes)
VALUES
    ((SELECT $node_id FROM Technique WHERE id = 7),
     (SELECT $node_id FROM Recipe WHERE id = 5), 2, 5,  NULL, N'Соединить всё с кефиром');
INSERT INTO AppliedIn ($from_id, $to_id, step_number, duration_min, temperature_c, notes)
VALUES
    ((SELECT $node_id FROM Technique WHERE id = 3),
     (SELECT $node_id FROM Recipe WHERE id = 6), 1, 60, 90, N'Тушить свинину в соусе');
INSERT INTO AppliedIn ($from_id, $to_id, step_number, duration_min, temperature_c, notes)
VALUES
    ((SELECT $node_id FROM Technique WHERE id = 6),
     (SELECT $node_id FROM Recipe WHERE id = 6), 2, 10, NULL, N'Замесить тесто для блинов');
INSERT INTO AppliedIn ($from_id, $to_id, step_number, duration_min, temperature_c, notes)
VALUES
    ((SELECT $node_id FROM Technique WHERE id = 2),
     (SELECT $node_id FROM Recipe WHERE id = 6), 3, 30, 180, N'Жарить блины');
INSERT INTO AppliedIn ($from_id, $to_id, step_number, duration_min, temperature_c, notes)
VALUES
    ((SELECT $node_id FROM Technique WHERE id = 3),
     (SELECT $node_id FROM Recipe WHERE id = 7), 1, 90, 95, N'Тушить говядину с овощами и паприкой');
INSERT INTO AppliedIn ($from_id, $to_id, step_number, duration_min, temperature_c, notes)
VALUES
    ((SELECT $node_id FROM Technique WHERE id = 7),
     (SELECT $node_id FROM Recipe WHERE id = 7), 2, 5,  NULL, N'Добавить томатную пасту, перемешать');
INSERT INTO AppliedIn ($from_id, $to_id, step_number, duration_min, temperature_c, notes)
VALUES
    ((SELECT $node_id FROM Technique WHERE id = 9),
     (SELECT $node_id FROM Recipe WHERE id = 8), 1, 3,  NULL, N'Взбить яйца венчиком');
INSERT INTO AppliedIn ($from_id, $to_id, step_number, duration_min, temperature_c, notes)
VALUES
    ((SELECT $node_id FROM Technique WHERE id = 2),
     (SELECT $node_id FROM Recipe WHERE id = 8), 2, 5,  160, N'Жарить на слабом огне, свернуть');
INSERT INTO AppliedIn ($from_id, $to_id, step_number, duration_min, temperature_c, notes)
VALUES
    ((SELECT $node_id FROM Technique WHERE id = 6),
     (SELECT $node_id FROM Recipe WHERE id = 9), 1, 5,  NULL, N'Смешать тесто');
INSERT INTO AppliedIn ($from_id, $to_id, step_number, duration_min, temperature_c, notes)
VALUES
    ((SELECT $node_id FROM Technique WHERE id = 2),
     (SELECT $node_id FROM Recipe WHERE id = 9), 2, 20, 170, N'Жарить на сковороде');
INSERT INTO AppliedIn ($from_id, $to_id, step_number, duration_min, temperature_c, notes)
VALUES
    ((SELECT $node_id FROM Technique WHERE id = 9),
     (SELECT $node_id FROM Recipe WHERE id = 10), 1, 5,  NULL, N'Взбить желтки с сахаром');
INSERT INTO AppliedIn ($from_id, $to_id, step_number, duration_min, temperature_c, notes)
VALUES
    ((SELECT $node_id FROM Technique WHERE id = 4),
     (SELECT $node_id FROM Recipe WHERE id = 10), 2, 40, 160, N'Запекать на водяной бане');
INSERT INTO AppliedIn ($from_id, $to_id, step_number, duration_min, temperature_c, notes)
VALUES
    ((SELECT $node_id FROM Technique WHERE id = 8),
     (SELECT $node_id FROM Recipe WHERE id = 10), 3, 5,  NULL, N'Карамелизировать верхний слой сахара горелкой');
INSERT INTO AppliedIn ($from_id, $to_id, step_number, duration_min, temperature_c, notes)
VALUES
    ((SELECT $node_id FROM Technique WHERE id = 3),
     (SELECT $node_id FROM Recipe WHERE id = 11), 1, 45, 90, N'Тушить мясной соус');
INSERT INTO AppliedIn ($from_id, $to_id, step_number, duration_min, temperature_c, notes)
VALUES
    ((SELECT $node_id FROM Technique WHERE id = 1),
     (SELECT $node_id FROM Recipe WHERE id = 11), 2, 10, 100, N'Варить спагетти до al dente');
INSERT INTO AppliedIn ($from_id, $to_id, step_number, duration_min, temperature_c, notes)
VALUES
    ((SELECT $node_id FROM Technique WHERE id = 6),
     (SELECT $node_id FROM Recipe WHERE id = 12), 1, 10, NULL, N'Замесить жидкое тесто');
INSERT INTO AppliedIn ($from_id, $to_id, step_number, duration_min, temperature_c, notes)
VALUES
    ((SELECT $node_id FROM Technique WHERE id = 2),
     (SELECT $node_id FROM Recipe WHERE id = 12), 2, 30, 190, N'Жарить тонкие блины на сковороде');
GO


-- 4.3 CanReplace: Ингредиент → Ингредиент (заменяемость)
-- Направление: A → B: «ингредиент A можно заменить на B»

INSERT INTO CanReplace ($from_id, $to_id, quality_loss, ratio, verified_date, comment)
VALUES
    ((SELECT $node_id FROM Ingredient WHERE id = 8),
     (SELECT $node_id FROM Ingredient WHERE id = 16),
     N'минимальная', N'1:1', '2024-01-10',
     N'Кефир делает блины пышнее, вкус немного кислее');
INSERT INTO CanReplace ($from_id, $to_id, quality_loss, ratio, verified_date, comment)
VALUES
    ((SELECT $node_id FROM Ingredient WHERE id = 16),
     (SELECT $node_id FROM Ingredient WHERE id = 8),
     N'умеренная', N'1:1', '2024-01-10',
     N'Оладьи получатся менее пышными');
INSERT INTO CanReplace ($from_id, $to_id, quality_loss, ratio, verified_date, comment)
VALUES
    ((SELECT $node_id FROM Ingredient WHERE id = 9),
     (SELECT $node_id FROM Ingredient WHERE id = 18),
     N'умеренная', N'1:0.8', '2024-02-15',
     N'Сливки предпочтительнее для крем-брюле, сметана даёт кислинку');
INSERT INTO CanReplace ($from_id, $to_id, quality_loss, ratio, verified_date, comment)
VALUES
    ((SELECT $node_id FROM Ingredient WHERE id = 3),
     (SELECT $node_id FROM Ingredient WHERE id = 4),
     N'минимальная', N'1:1', '2023-11-05',
     N'Свинина делает блюдо жирнее, но вкус похожий');
INSERT INTO CanReplace ($from_id, $to_id, quality_loss, ratio, verified_date, comment)
VALUES
    ((SELECT $node_id FROM Ingredient WHERE id = 4),
     (SELECT $node_id FROM Ingredient WHERE id = 3),
     N'минимальная', N'1:1', '2023-11-05',
     N'Начинка получится менее жирной');
INSERT INTO CanReplace ($from_id, $to_id, quality_loss, ratio, verified_date, comment)
VALUES
    ((SELECT $node_id FROM Ingredient WHERE id = 5),
     (SELECT $node_id FROM Ingredient WHERE id = 20),
     N'умеренная', N'1:1', '2024-03-01',
     N'Болоньезе с куриным фаршем — более диетический вариант');
INSERT INTO CanReplace ($from_id, $to_id, quality_loss, ratio, verified_date, comment)
VALUES
    ((SELECT $node_id FROM Ingredient WHERE id = 20),
     (SELECT $node_id FROM Ingredient WHERE id = 5),
     N'умеренная', N'1:1', '2024-03-01',
     N'Куриный фарш менее жирный, соус будет светлее');
INSERT INTO CanReplace ($from_id, $to_id, quality_loss, ratio, verified_date, comment)
VALUES
    ((SELECT $node_id FROM Ingredient WHERE id = 15),
     (SELECT $node_id FROM Ingredient WHERE id = 9),
     N'умеренная', N'1:1.2', '2024-04-01',
     N'Сметана придаёт мягкость тесту, вкус немного другой');
INSERT INTO CanReplace ($from_id, $to_id, quality_loss, ratio, verified_date, comment)
VALUES
    ((SELECT $node_id FROM Ingredient WHERE id = 18),
     (SELECT $node_id FROM Ingredient WHERE id = 8),
     N'умеренная', N'1:1', '2024-01-20',
     N'Молоко менее жирное, омлет потеряет кремовость');
INSERT INTO CanReplace ($from_id, $to_id, quality_loss, ratio, verified_date, comment)
VALUES
    ((SELECT $node_id FROM Ingredient WHERE id = 10),
     (SELECT $node_id FROM Ingredient WHERE id = 2),
     N'значительная', N'по рецепту', '2024-02-28',
     N'Картофельный крахмал из картофеля можно использовать для загущения вместо муки');
INSERT INTO CanReplace ($from_id, $to_id, quality_loss, ratio, verified_date, comment)
VALUES
    ((SELECT $node_id FROM Ingredient WHERE id = 19),
     (SELECT $node_id FROM Ingredient WHERE id = 12),
     N'умеренная', N'1:1', '2024-05-01',
     N'Морковная ботва или петрушка как замена укропу в холоднике');
INSERT INTO CanReplace ($from_id, $to_id, quality_loss, ratio, verified_date, comment)
VALUES
    ((SELECT $node_id FROM Ingredient WHERE id = 14),
     (SELECT $node_id FROM Ingredient WHERE id = 1),
     N'минимальная', N'50г→100г свёклы', '2024-03-10',
     N'Свёкла даёт цвет и натуральную кислоту вместо томата');
GO


-- 4.4 UsedBy: Рецепт → Повар

INSERT INTO UsedBy ($from_id, $to_id, since_year, is_signature, rating, comment)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 1),
     (SELECT $node_id FROM Chef WHERE id = 1), 2005, 1, 9.5, N'Фирменный борщ с говяжьими рёбрами');
INSERT INTO UsedBy ($from_id, $to_id, since_year, is_signature, rating, comment)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 1),
     (SELECT $node_id FROM Chef WHERE id = 2), 2000, 0, 9.0, N'Классический борщ в ресторанном меню');
INSERT INTO UsedBy ($from_id, $to_id, since_year, is_signature, rating, comment)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 2),
     (SELECT $node_id FROM Chef WHERE id = 4), 2010, 1, 9.2, N'Фирменные драники с домашней сметаной');
INSERT INTO UsedBy ($from_id, $to_id, since_year, is_signature, rating, comment)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 2),
     (SELECT $node_id FROM Chef WHERE id = 1), 2008, 0, 8.8, N'Традиционный рецепт без добавок');
INSERT INTO UsedBy ($from_id, $to_id, since_year, is_signature, rating, comment)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 3),
     (SELECT $node_id FROM Chef WHERE id = 3), 2012, 1, 9.3, N'Авторские пельмени с тремя видами мяса');
INSERT INTO UsedBy ($from_id, $to_id, since_year, is_signature, rating, comment)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 3),
     (SELECT $node_id FROM Chef WHERE id = 9), 2018, 0, 8.5, N'Домашние пельмени по бабушкиному рецепту');
INSERT INTO UsedBy ($from_id, $to_id, since_year, is_signature, rating, comment)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 4),
     (SELECT $node_id FROM Chef WHERE id = 2), 1999, 0, 8.7, N'Оливье с докторской колбасой');
INSERT INTO UsedBy ($from_id, $to_id, since_year, is_signature, rating, comment)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 4),
     (SELECT $node_id FROM Chef WHERE id = 9), 2015, 0, 8.2, N'Новогодний оливье');
INSERT INTO UsedBy ($from_id, $to_id, since_year, is_signature, rating, comment)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 5),
     (SELECT $node_id FROM Chef WHERE id = 4), 2012, 1, 9.0, N'Летний холодник со свежим огурцом');
INSERT INTO UsedBy ($from_id, $to_id, since_year, is_signature, rating, comment)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 5),
     (SELECT $node_id FROM Chef WHERE id = 10), 2017, 0, 8.6, N'Холодник без сметаны, лёгкий вариант');
INSERT INTO UsedBy ($from_id, $to_id, since_year, is_signature, rating, comment)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 6),
     (SELECT $node_id FROM Chef WHERE id = 1), 2007, 1, 9.7, N'Фирменная мачанка по рецепту деда');
INSERT INTO UsedBy ($from_id, $to_id, since_year, is_signature, rating, comment)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 7),
     (SELECT $node_id FROM Chef WHERE id = 6), 2003, 1, 9.4, N'Аутентичный венгерский гуляш');
INSERT INTO UsedBy ($from_id, $to_id, since_year, is_signature, rating, comment)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 8),
     (SELECT $node_id FROM Chef WHERE id = 5), 1995, 0, 9.1, N'Классический французский омлет');
INSERT INTO UsedBy ($from_id, $to_id, since_year, is_signature, rating, comment)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 8),
     (SELECT $node_id FROM Chef WHERE id = 8), 2019, 0, 8.4, N'Омлет с зеленью для вегетарианцев');
INSERT INTO UsedBy ($from_id, $to_id, since_year, is_signature, rating, comment)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 9),
     (SELECT $node_id FROM Chef WHERE id = 9), 2016, 0, 8.9, N'Пышные оладьи на кефире');
INSERT INTO UsedBy ($from_id, $to_id, since_year, is_signature, rating, comment)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 9),
     (SELECT $node_id FROM Chef WHERE id = 2), 2010, 0, 8.8, N'Оладьи с ягодным вареньем');
INSERT INTO UsedBy ($from_id, $to_id, since_year, is_signature, rating, comment)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 10),
     (SELECT $node_id FROM Chef WHERE id = 5), 1990, 1, 9.8, N'Фирменный крем-брюле с ванилью');
INSERT INTO UsedBy ($from_id, $to_id, since_year, is_signature, rating, comment)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 10),
     (SELECT $node_id FROM Chef WHERE id = 10), 2020, 0, 9.0, N'Крем-брюле с белорусской карамелью');
INSERT INTO UsedBy ($from_id, $to_id, since_year, is_signature, rating, comment)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 11),
     (SELECT $node_id FROM Chef WHERE id = 7), 2001, 1, 9.6, N'Болоньезе по рецепту нонны');
INSERT INTO UsedBy ($from_id, $to_id, since_year, is_signature, rating, comment)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 12),
     (SELECT $node_id FROM Chef WHERE id = 2), 1998, 1, 9.2, N'Тонкие русские блины к масленице');
INSERT INTO UsedBy ($from_id, $to_id, since_year, is_signature, rating, comment)
VALUES
    ((SELECT $node_id FROM Recipe WHERE id = 12),
     (SELECT $node_id FROM Chef WHERE id = 9), 2014, 0, 8.7, N'Блины с мёдом и маслом');
GO


-- ПРОВЕРКА: содержимое всех таблиц

SELECT N'Рецепты'                    AS [Таблица], COUNT(*) AS [Строк] FROM Recipe
UNION ALL
SELECT N'Ингредиенты',                          COUNT(*) FROM Ingredient
UNION ALL
SELECT N'Техники',                              COUNT(*) FROM Technique
UNION ALL
SELECT N'Повара',                               COUNT(*) FROM Chef
UNION ALL
SELECT N'Рецепт-Ингредиент (состав)',           COUNT(*) FROM RecipeIngredient
UNION ALL
SELECT N'Применяется в рецепте',                COUNT(*) FROM AppliedIn
UNION ALL
SELECT N'Может заменить',                       COUNT(*) FROM CanReplace
UNION ALL
SELECT N'Используется поваром',                 COUNT(*) FROM UsedBy;
GO

-- ЧАСТЬ 5: ЗАПРОСЫ MATCH (5 запросов, цепочки 3+ узлов)


-- Запрос 1: Какие ингредиенты входят в рецепты
-- Цепочка: Chef ← (UsedBy) ← Recipe → (RecipeIngredient) → Ingredient

SELECT
    c.name          AS [Повар],
    r.name          AS [Рецепт],
    r.cuisine       AS [Кухня],
    i.name          AS [Ингредиент],
    i.category      AS [Категория],
    cont.quantity   AS [Количество],
    cont.unit       AS [Единица],
    cont.is_optional AS [Необязательный]
FROM Chef        AS c
   , UsedBy      AS ub
   , Recipe      AS r
   , RecipeIngredient    AS cont
   , Ingredient  AS i
WHERE MATCH(c<-(ub)-r-(cont)->i)
  AND c.name = N'Алексей Дудченко'
ORDER BY r.name, i.name;
GO

-- Запрос 2: Какие техники применяются в рецептах мастеров кухни
-- Цепочка: Technique → (AppliedIn) → Recipe ← (UsedBy) ← Chef

SELECT
    c.name              AS [Шеф-повар],
    c.country           AS [Страна],
    r.name              AS [Рецепт],
    r.difficulty        AS [Сложность],
    t.name              AS [Техника],
    t.technique_type    AS [Тип техники],
    ai.step_number      AS [Шаг],
    ai.duration_min     AS [Длительность (мин)]
FROM Chef       AS c
   , UsedBy     AS ub
   , Recipe     AS r
   , AppliedIn  AS ai
   , Technique  AS t
WHERE MATCH(c<-(ub)-r<-(ai)-t)
  AND c.level = N'мастер'
ORDER BY c.name, r.name, ai.step_number;
GO

-- Запрос 3: Найти заменители ингредиентов, входящих в блюда
-- Цепочка: Recipe → (RecipeIngredient) → Ingredient → (CanReplace) → Ingredient2

SELECT
    r.name          AS [Рецепт],
    i1.name         AS [Исходный ингредиент],
    i1.category     AS [Категория],
    cr.quality_loss AS [Потеря качества],
    cr.ratio        AS [Соотношение замены],
    i2.name         AS [Заменитель],
    cr.comment      AS [Комментарий]
FROM Recipe      AS r
   , RecipeIngredient    AS cont
   , Ingredient  AS i1
   , CanReplace  AS cr
   , Ingredient  AS i2
WHERE MATCH(r-(cont)->i1-(cr)->i2)
  AND r.cuisine = N'белорусская'
ORDER BY r.name, cr.quality_loss;
GO


-- Запрос 4: Повара, чьи фирменные рецепты содержат блюдо
-- Цепочка: Chef ← (UsedBy) ← Recipe → (RecipeIngredient) → Ingredient

SELECT DISTINCT
    c.name              AS [Шеф-повар],
    c.specialization    AS [Специализация],
    r.name              AS [Рецепт],
    r.cook_time_min     AS [Время (мин)],
    r.difficulty        AS [Сложность],
    i.name              AS [Ингредиент],
    i.category          AS [Категория],
    cont.quantity       AS [Количество],
    cont.unit           AS [Единица]
FROM Chef       AS c
   , UsedBy     AS ub
   , Recipe     AS r
   , RecipeIngredient   AS cont
   , Ingredient AS i
WHERE MATCH(c<-(ub)-r-(cont)->i)
  AND ub.is_signature  = 1
  AND r.cook_time_min  > 60
ORDER BY c.name, r.name, i.name;
GO


-- Запрос 5: Какие техники нужны для рецептов с ингредиентами
-- Цепочка: Technique → (AppliedIn) → Recipe → (RecipeIngredient) → Ingredient

SELECT DISTINCT
    t.name              AS [Техника],
    t.technique_type    AS [Тип техники],
    t.requires_equipment AS [Оборудование],
    r.name              AS [Рецепт],
    r.cuisine           AS [Кухня],
    i.name              AS [Мясной ингредиент],
    ai.temperature_c    AS [Температура °C],
    ai.duration_min     AS [Длительность (мин)]
FROM Technique  AS t
   , AppliedIn  AS ai
   , Recipe     AS r
   , RecipeIngredient   AS cont
   , Ingredient AS i
WHERE MATCH(t-(ai)->r-(cont)->i)
  AND i.category = N'мясо'
ORDER BY t.name, r.name;
GO

-- ЧАСТЬ 6: ЗАПРОСЫ SHORTEST_PATH


-- SP-Запрос 1: Все цепочки заменяемости, начиная с молока

SELECT
    i1.name AS [Начальный ингредиент],
    STRING_AGG(i2.name, N' -> ') WITHIN GROUP (GRAPH PATH) AS [Цепочка замен],
    COUNT(i2.name)               WITHIN GROUP (GRAPH PATH) AS [Длина цепочки],
    LAST_VALUE(i2.name)          WITHIN GROUP (GRAPH PATH) AS [Конечный ингредиент]
FROM Ingredient AS i1
   , CanReplace FOR PATH AS cr
   , Ingredient FOR PATH AS i2
WHERE MATCH(SHORTEST_PATH(i1(-(cr)->i2)+))
  AND i1.name = N'Молоко'
ORDER BY [Длина цепочки];
GO

-- SP-Запрос 2: Кратчайший путь заменяемости от "Жирные сливки 33%"

WITH PathCTE AS
(
    SELECT
        i1.name AS [Начало],
        STRING_AGG(i2.name, N' -> ') WITHIN GROUP (GRAPH PATH) AS [Путь замен],
        COUNT(i2.name)               WITHIN GROUP (GRAPH PATH) AS [Длина пути],
        LAST_VALUE(i2.name)          WITHIN GROUP (GRAPH PATH) AS [Конец]
    FROM Ingredient AS i1
       , CanReplace FOR PATH AS cr
       , Ingredient FOR PATH AS i2
    WHERE MATCH(SHORTEST_PATH(i1(-(cr)->i2)+))
      AND i1.name = N'Жирные сливки 33%'
)
SELECT [Начало], [Путь замен], [Длина пути]
FROM PathCTE
WHERE [Конец] = N'Кефир';
GO

-- SP-Запрос 3: Все цепочки заменяемости глубиной от 1 до 3 шагов

SELECT
    i1.name AS [Исходный ингредиент],
    STRING_AGG(i2.name, N' -> ') WITHIN GROUP (GRAPH PATH) AS [Путь замен],
    COUNT(i2.name)               WITHIN GROUP (GRAPH PATH) AS [Длина пути],
    LAST_VALUE(i2.name)          WITHIN GROUP (GRAPH PATH) AS [Конечный ингредиент]
FROM Ingredient AS i1
   , CanReplace FOR PATH AS cr
   , Ingredient FOR PATH AS i2
WHERE MATCH(SHORTEST_PATH(i1(-(cr)->i2){1,3}))
ORDER BY i1.name, [Длина пути];
GO