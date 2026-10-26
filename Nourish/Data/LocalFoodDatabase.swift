import Foundation

enum LocalFoodDatabase {
    static let entries: [FoodNutritionEntry] = [
        entry("Greek yogurt", ["greek yogurt", "yogurt", "plain yogurt", "酸奶", "希腊酸奶"], 59, 10, 3.6, 0.4, [
            serving("1 cup", 225, 180, 250),
            serving("small bowl", 170, 140, 200)
        ]),
        entry("Mochi", ["mochi", "mochi ball", "mochi pieces", "麻薯", "糯米糍"], 260, 2.5, 58, 1, [
            serving("1 piece", 35, 25, 45)
        ]),
        entry("Protein bar", ["protein bar", "protein bars", "bar", "quest bar", "rxbar", "蛋白棒"], 360, 33, 35, 10, [
            serving("1 bar", 60, 50, 70)
        ]),
        entry("Oikos protein yogurt", ["oikos", "oikos yogurt", "oikos pro", "protein yogurt"], 83, 14, 6, 0.3, [
            serving("1 cup", 170, 150, 190),
            serving("1 container", 150, 130, 180)
        ]),
        entry("Siggi's skyr", ["siggis", "siggi's", "skyr", "icelandic yogurt"], 75, 12, 6, 0.2, [
            serving("1 cup", 170, 150, 200),
            serving("1 container", 150, 130, 180)
        ]),
        entry("Yogurt bowl", ["yogurt bowl", "greek yogurt bowl", "protein yogurt bowl"], 120, 10, 13, 3, [
            serving("bowl", 300, 230, 420),
            serving("small bowl", 220, 170, 300)
        ]),
        entry("Built protein bar", ["built bar", "built protein bar"], 350, 30, 38, 8, [
            serving("1 bar", 49, 42, 60)
        ]),
        entry("Barebells protein bar", ["barebells", "barebells bar", "barebells protein bar"], 360, 33, 32, 12, [
            serving("1 bar", 55, 50, 65)
        ]),
        entry("Protein chips", ["protein chips", "quest chips"], 365, 43, 18, 13, [
            serving("1 bag", 32, 28, 40)
        ]),
        entry("Chicken breast", ["chicken breast", "chicken", "鸡胸肉", "鸡肉"], 165, 31, 0, 3.6, [
            serving("4 oz", 113, 90, 140),
            serving("palm-size serving", 120, 90, 150)
        ]),
        entry("Salmon", ["salmon", "三文鱼", "鲑鱼"], 208, 20, 0, 13, [
            serving("4 oz", 113, 90, 140),
            serving("fillet", 160, 120, 220)
        ]),
        entry("Eggs", ["egg", "eggs", "鸡蛋", "蛋"], 143, 13, 1.1, 10, [
            serving("1 egg", 50, 42, 58)
        ]),
        entry("Rice", ["rice", "white rice", "brown rice", "米饭", "饭", "白米饭"], 130, 2.7, 28, 0.3, [
            serving("1 cup", 158, 130, 190),
            serving("bowl", 220, 160, 300)
        ]),
        entry("Pasta", ["pasta", "noodles", "面", "面条", "意面"], 158, 5.8, 31, 0.9, [
            serving("1 cup", 140, 110, 180),
            serving("bowl", 220, 160, 300)
        ]),
        entry("Pad Thai", ["pad thai", "padthai", "ผัดไทย", "泰式炒河粉", "泰式炒粉"], 190, 7, 27, 6, [
            serving("plate", 420, 320, 580),
            serving("bowl", 380, 280, 520),
            serving("serving", 400, 300, 560)
        ]),
        entry("Pad see ew", ["pad see ew", "pad see you", "ผัดซีอิ๊ว", "泰式炒河粉"], 185, 8, 24, 7, [
            serving("plate", 430, 320, 600),
            serving("bowl", 390, 290, 540),
            serving("serving", 410, 300, 560)
        ]),
        entry("Drunken noodles", ["drunken noodles", "pad kee mao", "ผัดขี้เมา", "泰式醉面"], 180, 7, 23, 6, [
            serving("plate", 430, 320, 600),
            serving("bowl", 390, 290, 540),
            serving("serving", 410, 300, 560)
        ]),
        entry("Pho", ["pho", "pho bo", "pho ga", "越南河粉", "粉"], 70, 5, 8, 2.5, [
            serving("bowl", 520, 380, 700),
            serving("large bowl", 680, 520, 900)
        ]),
        entry("Ramen", ["ramen", "ラーメン", "拉面", "拉麵"], 135, 6, 16, 5, [
            serving("bowl", 520, 380, 700),
            serving("large bowl", 680, 520, 900)
        ]),
        entry("Udon", ["udon", "うどん", "乌冬面", "烏冬麵"], 132, 4.2, 23, 1.8, [
            serving("bowl", 480, 360, 650),
            serving("large bowl", 620, 480, 820)
        ]),
        entry("Soba", ["soba", "そば", "荞麦面", "蕎麥麵"], 125, 5.5, 24, 0.8, [
            serving("bowl", 460, 340, 620),
            serving("large bowl", 600, 460, 800)
        ]),
        entry("Japchae", ["japchae", "잡채", "韩式杂菜", "韓式雜菜"], 150, 3.5, 24, 4, [
            serving("plate", 250, 180, 340),
            serving("bowl", 300, 220, 400)
        ]),
        entry("Tteokbokki", ["tteokbokki", "tteokbokki bowl", "떡볶이", "韩式炒年糕", "韓式炒年糕"], 175, 4, 32, 2.5, [
            serving("bowl", 320, 240, 430),
            serving("plate", 280, 210, 380)
        ]),
        entry("Bibimbap", ["bibimbap", "비빔밥", "拌饭", "拌飯", "korean rice bowl"], 145, 6, 19, 5, [
            serving("bowl", 500, 380, 680),
            serving("small bowl", 360, 280, 500)
        ]),
        entry("Kimchi fried rice", ["kimchi fried rice", "kimchi bokkeumbap", "김치볶음밥", "泡菜炒饭", "泡菜炒飯"], 185, 5, 30, 5, [
            serving("bowl", 380, 280, 520),
            serving("plate", 420, 320, 560)
        ]),
        entry("Fried rice", ["fried rice", "egg fried rice", "炒饭", "炒飯"], 180, 4.5, 31, 3.5, [
            serving("bowl", 350, 260, 480),
            serving("plate", 400, 300, 540)
        ]),
        entry("Congee", ["congee", "jook", "粥", "皮蛋瘦肉粥"], 55, 2.2, 10, 0.7, [
            serving("bowl", 400, 300, 550),
            serving("small bowl", 280, 210, 380)
        ]),
        entry("Mapo tofu", ["mapo tofu", "mapo doufu", "麻婆豆腐"], 140, 8, 6, 9, [
            serving("bowl", 280, 210, 380),
            serving("plate", 320, 240, 430)
        ]),
        entry("Dan dan noodles", ["dan dan noodles", "dan dan mian", "担担面", "擔擔麵"], 175, 7, 24, 6, [
            serving("bowl", 380, 280, 520),
            serving("plate", 420, 320, 580)
        ]),
        entry("Zhajiangmian", ["zhajiangmian", "zha jiang mian", "炸酱面", "炸醬麵"], 180, 8, 25, 6, [
            serving("bowl", 400, 300, 550),
            serving("plate", 440, 330, 600)
        ]),
        entry("Lo mein", ["lo mein", "撈麵", "捞面"], 175, 6, 28, 4.5, [
            serving("plate", 420, 320, 580),
            serving("bowl", 380, 280, 520)
        ]),
        entry("Chow mein", ["chow mein", "炒面", "炒麵"], 185, 7, 27, 6, [
            serving("plate", 420, 320, 580),
            serving("bowl", 380, 280, 520)
        ]),
        entry("Beef broccoli", ["beef broccoli", "beef with broccoli", "西兰花牛肉", "西蘭花牛肉"], 150, 12, 7, 8, [
            serving("plate", 300, 220, 420),
            serving("bowl", 260, 190, 360)
        ]),
        entry("Tomato egg stir fry", ["tomato egg stir fry", "stir fried tomato and egg", "番茄炒蛋", "西红柿炒鸡蛋"], 110, 6, 5, 7, [
            serving("plate", 220, 160, 300),
            serving("bowl", 260, 190, 360)
        ]),
        entry("Xiao long bao", ["xiao long bao", "soup dumplings", "小笼包", "小籠包"], 215, 9, 24, 8, [
            serving("6 pieces", 180, 130, 240),
            serving("8 pieces", 240, 180, 320),
            serving("1 piece", 30, 22, 40)
        ]),
        entry("Wonton soup", ["wonton soup", "云吞汤", "雲吞湯", "馄饨汤", "餛飩湯"], 55, 3.5, 6, 2, [
            serving("bowl", 420, 320, 580),
            serving("large bowl", 560, 430, 760)
        ]),
        entry("Wonton noodles", ["wonton noodles", "wonton noodle soup", "云吞面", "雲吞麵", "馄饨面"], 135, 6, 19, 3.5, [
            serving("bowl", 460, 350, 630),
            serving("large bowl", 620, 470, 840)
        ]),
        entry("Scallion pancakes", ["scallion pancake", "scallion pancakes", "葱油饼", "蔥油餅"], 320, 7, 42, 13, [
            serving("1 pancake", 100, 75, 130),
            serving("2 pancakes", 200, 150, 260)
        ]),
        entry("Char siu", ["char siu", "bbq pork", "叉烧", "叉燒"], 250, 20, 8, 14, [
            serving("serving", 120, 90, 170),
            serving("plate", 180, 130, 240)
        ]),
        entry("Char siu rice", ["char siu rice", "bbq pork rice", "叉烧饭", "叉燒飯"], 180, 9, 22, 5.5, [
            serving("bowl", 420, 320, 580),
            serving("plate", 460, 350, 620)
        ]),
        entry("Roast duck", ["roast duck", "peking duck", "烤鸭", "燒鴨", "烧鸭"], 330, 19, 2, 28, [
            serving("serving", 120, 90, 170),
            serving("plate", 180, 130, 240)
        ]),
        entry("Hot pot", ["hot pot", "malatang", "麻辣烫", "麻辣燙", "火锅", "火鍋"], 110, 7, 8, 6, [
            serving("bowl", 500, 360, 700),
            serving("large bowl", 700, 520, 950)
        ]),
        entry("Teriyaki chicken", ["teriyaki chicken", "chicken teriyaki", "照烧鸡", "照燒雞"], 185, 18, 10, 8, [
            serving("plate", 220, 170, 300),
            serving("bowl", 280, 210, 380)
        ]),
        entry("Teriyaki chicken bowl", ["teriyaki chicken bowl", "chicken teriyaki bowl", "teriyaki bowl"], 155, 10, 19, 4.5, [
            serving("bowl", 500, 380, 680),
            serving("small bowl", 360, 280, 500)
        ]),
        entry("Orange chicken", ["orange chicken", "陈皮鸡", "陳皮雞"], 255, 14, 20, 13, [
            serving("plate", 220, 170, 300),
            serving("bowl", 280, 210, 380)
        ]),
        entry("Kung pao chicken", ["kung pao chicken", "gong bao chicken", "宫保鸡丁", "宮保雞丁"], 210, 16, 10, 12, [
            serving("plate", 220, 170, 300),
            serving("bowl", 280, 210, 380)
        ]),
        entry("Bulgogi", ["bulgogi", "불고기", "korean beef", "韩式烤牛肉", "韓式烤牛肉"], 215, 17, 9, 13, [
            serving("plate", 220, 170, 300),
            serving("bowl", 280, 210, 380)
        ]),
        entry("Galbi", ["galbi", "kalbi", "갈비", "short ribs", "韩式排骨", "韓式排骨"], 290, 18, 6, 22, [
            serving("serving", 170, 120, 230),
            serving("plate", 240, 180, 320)
        ]),
        entry("Samgyeopsal", ["samgyeopsal", "삼겹살", "pork belly", "烤五花肉"], 330, 12, 0, 30, [
            serving("serving", 150, 110, 210),
            serving("plate", 220, 160, 300)
        ]),
        entry("Kimchi jjigae", ["kimchi jjigae", "kimchi stew", "김치찌개", "泡菜汤", "泡菜湯"], 85, 6, 5, 4.5, [
            serving("bowl", 420, 320, 580),
            serving("large bowl", 560, 430, 760)
        ]),
        entry("Sundubu jjigae", ["sundubu", "sundubu jjigae", "soft tofu stew", "순두부찌개", "嫩豆腐汤", "嫩豆腐湯"], 95, 7, 4, 6, [
            serving("bowl", 400, 300, 550),
            serving("large bowl", 540, 410, 730)
        ]),
        entry("Doenjang jjigae", ["doenjang jjigae", "soybean paste stew", "된장찌개", "大酱汤", "大醬湯"], 75, 5, 6, 3.5, [
            serving("bowl", 400, 300, 550),
            serving("large bowl", 540, 410, 730)
        ]),
        entry("Kongnamul", ["kongnamul", "seasoned bean sprouts", "콩나물무침", "韩式豆芽", "韓式豆芽"], 45, 2.5, 5, 1.8, [
            serving("serving", 90, 65, 130),
            serving("small plate", 60, 40, 90)
        ]),
        entry("Sigeumchi namul", ["sigeumchi namul", "seasoned spinach", "시금치나물", "韩式菠菜", "韓式菠菜"], 55, 2.5, 4, 3, [
            serving("serving", 80, 55, 110),
            serving("small plate", 55, 35, 80)
        ]),
        entry("Oi muchim", ["oi muchim", "seasoned cucumber", "오이무침", "韩式黄瓜", "韓式黃瓜"], 35, 1, 5, 1.2, [
            serving("serving", 90, 65, 130),
            serving("small plate", 60, 40, 90)
        ]),
        entry("Gamja jorim", ["gamja jorim", "braised potatoes", "감자조림", "韩式土豆", "韓式土豆"], 110, 2, 18, 3.5, [
            serving("serving", 100, 75, 140),
            serving("small plate", 70, 50, 100)
        ]),
        entry("Myulchi bokkeum", ["myulchi bokkeum", "stir fried anchovies", "멸치볶음", "韩式小鱼干", "韓式小魚乾"], 220, 20, 14, 10, [
            serving("serving", 35, 24, 50),
            serving("small plate", 25, 18, 36)
        ]),
        entry("Pickled radish", ["pickled radish", "danmuji", "단무지", "腌萝卜", "醃蘿蔔"], 45, 0.7, 10, 0.1, [
            serving("serving", 60, 40, 90),
            serving("small plate", 40, 28, 60)
        ]),
        entry("Naengmyeon", ["naengmyeon", "cold noodles", "냉면", "冷面", "冷麵"], 125, 4.5, 24, 1.5, [
            serving("bowl", 450, 340, 620),
            serving("large bowl", 600, 460, 820)
        ]),
        entry("Ramyun", ["ramyun", "ramyeon", "shin ramyun", "라면", "辛拉面", "辛拉麵"], 145, 4.5, 22, 5.5, [
            serving("bowl", 500, 380, 680),
            serving("package", 520, 400, 700)
        ]),
        entry("Jajangmyeon", ["jajangmyeon", "jjajangmyeon", "black bean noodles", "짜장면", "炸酱面", "炸醬麵"], 165, 6, 28, 4, [
            serving("bowl", 420, 320, 580),
            serving("plate", 460, 350, 620)
        ]),
        entry("Korean fried chicken", ["korean fried chicken", "양념치킨", "fried chicken korean", "韩式炸鸡", "韓式炸雞"], 290, 18, 16, 18, [
            serving("4 pieces", 220, 160, 300),
            serving("6 pieces", 330, 240, 450),
            serving("1 piece", 55, 40, 75)
        ]),
        entry("Bossam", ["bossam", "보쌈", "boiled pork wraps", "韩式菜包肉", "韓式菜包肉"], 250, 18, 4, 16, [
            serving("serving", 180, 130, 240),
            serving("plate", 240, 180, 320)
        ]),
        entry("Japanese curry rice", ["japanese curry", "japanese curry rice", "curry rice", "カレーライス", "日式咖喱饭", "日式咖哩飯"], 155, 4, 22, 5, [
            serving("plate", 420, 320, 580),
            serving("bowl", 380, 280, 520)
        ]),
        entry("Thai green curry", ["thai green curry", "green curry", "แกงเขียวหวาน", "泰式绿咖喱", "泰式綠咖哩"], 125, 6, 7, 8, [
            serving("bowl", 320, 240, 430),
            serving("serving", 280, 210, 380)
        ]),
        entry("Thai red curry", ["thai red curry", "red curry", "แกงเผ็ด", "泰式红咖喱", "泰式紅咖哩"], 130, 6, 8, 8, [
            serving("bowl", 320, 240, 430),
            serving("serving", 280, 210, 380)
        ]),
        entry("Dumplings", ["dumplings", "dumpling", "gyoza", "jiaozi", "potstickers", "饺子", "鍋貼"], 210, 8, 26, 6, [
            serving("6 piece", 180, 130, 240),
            serving("6 pieces", 180, 130, 240),
            serving("10 piece", 300, 230, 390),
            serving("10 pieces", 300, 230, 390),
            serving("1 piece", 30, 22, 40)
        ]),
        entry("Bao", ["bao", "bao bun", "steamed bun", "包子", "刈包"], 245, 8, 35, 6, [
            serving("1 bun", 90, 65, 120),
            serving("2 buns", 180, 130, 240)
        ]),
        entry("Spring rolls", ["spring rolls", "spring roll", "fried spring roll", "春卷"], 230, 5, 26, 11, [
            serving("2 rolls", 100, 70, 140),
            serving("1 roll", 50, 35, 70)
        ]),
        entry("Summer rolls", ["summer rolls", "summer roll", "gỏi cuốn", "越南春卷"], 120, 5, 18, 2, [
            serving("2 rolls", 140, 100, 190),
            serving("1 roll", 70, 50, 95)
        ]),
        entry("Banh mi", ["banh mi", "bánh mì", "越南三明治"], 230, 12, 28, 7, [
            serving("1 sandwich", 260, 200, 340)
        ]),
        entry("Kimbap", ["kimbap", "gimbap", "김밥", "紫菜包饭", "紫菜包飯"], 170, 5, 28, 4, [
            serving("1 roll", 220, 170, 290),
            serving("8 pieces", 220, 170, 290)
        ]),
        entry("Onigiri", ["onigiri", "rice ball", "おにぎり", "饭团", "飯糰"], 180, 4, 37, 1.5, [
            serving("1 rice ball", 110, 85, 140),
            serving("2 rice balls", 220, 170, 280)
        ]),
        entry("Miso soup", ["miso soup", "味噌汤", "味噌湯"], 35, 2.5, 4, 1.2, [
            serving("1 cup", 240, 200, 300),
            serving("bowl", 280, 220, 340)
        ]),
        entry("Kimchi", ["kimchi", "kimchee", "김치", "泡菜", "韩国泡菜"], 15, 1.1, 2.4, 0.5, [
            serving("1/2 cup", 75, 55, 100),
            serving("serving", 85, 60, 120)
        ]),
        entry("Bok choy", ["bok choy", "上海青", "小白菜", "青江菜"], 13, 1.5, 2.2, 0.2, [
            serving("1 cup", 85, 60, 120),
            serving("plate", 140, 100, 200)
        ]),
        entry("Napa cabbage", ["napa cabbage", "chinese cabbage", "大白菜"], 16, 1.2, 3.2, 0.2, [
            serving("1 cup", 90, 65, 130),
            serving("plate", 150, 110, 210)
        ]),
        entry("Gai lan", ["gai lan", "chinese broccoli", "芥兰", "芥蘭"], 26, 2.6, 4.2, 0.5, [
            serving("plate", 120, 90, 170),
            serving("1 cup", 90, 65, 130)
        ]),
        entry("Shiitake mushrooms", ["shiitake", "shiitake mushrooms", "香菇"], 34, 2.2, 6.8, 0.5, [
            serving("1 cup", 85, 60, 120),
            serving("plate", 120, 90, 170)
        ]),
        entry("Enoki mushrooms", ["enoki", "enoki mushrooms", "金针菇", "金針菇"], 37, 2.7, 7.8, 0.3, [
            serving("bundle", 100, 75, 130),
            serving("plate", 120, 90, 160)
        ]),
        entry("Tofu skin", ["tofu skin", "bean curd skin", "yuba", "腐竹", "豆皮"], 190, 21, 8, 10, [
            serving("serving", 80, 55, 110),
            serving("plate", 120, 90, 170)
        ]),
        entry("Fish cake", ["fish cake", "fish cakes", "eomuk", "어묵", "鱼饼", "魚餅"], 160, 12, 16, 6, [
            serving("1 piece", 35, 25, 50),
            serving("serving", 120, 90, 170)
        ]),
        entry("Rice cakes", ["rice cakes", "tteok", "rice cake", "年糕", "떡"], 225, 4, 50, 0.4, [
            serving("serving", 120, 90, 170),
            serving("1 piece", 20, 14, 28)
        ]),
        entry("Bean sprouts", ["bean sprouts", "mung bean sprouts", "豆芽"], 31, 3, 6, 0.2, [
            serving("1 cup", 100, 70, 140),
            serving("plate", 140, 100, 200)
        ]),
        entry("Spam", ["spam", "luncheon meat", "午餐肉", "스팸"], 315, 13, 2, 28, [
            serving("serving", 84, 60, 110),
            serving("2 slices", 56, 42, 72)
        ]),
        entry("Soy milk", ["soy milk", "doujiang", "豆浆", "豆漿", "두유"], 45, 3.2, 3, 2, [
            serving("1 cup", 240, 210, 270),
            serving("bottle", 300, 260, 340)
        ]),
        entry("Tea egg", ["tea egg", "tea eggs", "茶叶蛋", "茶葉蛋"], 150, 13, 1.2, 10, [
            serving("1 egg", 50, 42, 58),
            serving("2 eggs", 100, 84, 116)
        ]),
        entry("Jianbing", ["jianbing", "jian bing", "煎饼", "煎餅"], 220, 8, 28, 8, [
            serving("1 crepe", 180, 130, 240)
        ]),
        entry("Youtiao", ["youtiao", "you tiao", "fried dough stick", "油条", "油條"], 390, 8, 41, 24, [
            serving("1 stick", 55, 40, 75),
            serving("2 sticks", 110, 80, 150)
        ]),
        entry("Sesame ball", ["sesame ball", "jian dui", "麻球", "芝麻球"], 380, 6, 52, 16, [
            serving("1 piece", 45, 32, 60),
            serving("2 pieces", 90, 64, 120)
        ]),
        entry("Red bean bun", ["red bean bun", "anpan", "red bean bread", "豆沙包", "紅豆包"], 265, 7, 46, 4, [
            serving("1 bun", 90, 65, 120),
            serving("2 buns", 180, 130, 240)
        ]),
        entry("Pineapple bun", ["pineapple bun", "bolo bao", "菠萝包", "菠蘿包"], 330, 7, 48, 12, [
            serving("1 bun", 95, 70, 130)
        ]),
        entry("Mooncake", ["mooncake", "mooncakes", "月饼", "月餅"], 420, 7, 56, 18, [
            serving("1 piece", 85, 65, 110)
        ]),
        entry("White Rabbit candy", ["white rabbit", "white rabbit candy", "大白兔", "大白兔奶糖"], 430, 3, 74, 10, [
            serving("1 candy", 6, 4, 8),
            serving("5 candies", 30, 22, 40)
        ]),
        entry("Pocky", ["pocky", "glico pocky", "百奇"], 500, 6, 67, 22, [
            serving("1 pack", 41, 32, 50),
            serving("1 box", 82, 64, 100)
        ]),
        entry("Yan Yan", ["yan yan", "meiji yan yan"], 490, 6, 66, 22, [
            serving("1 cup", 50, 40, 62)
        ]),
        entry("Yakult", ["yakult", "益力多"], 63, 1, 14, 0, [
            serving("1 bottle", 65, 55, 75),
            serving("5 bottles", 325, 280, 360)
        ]),
        entry("Calpico", ["calpico", "calpis", "可尔必思", "可爾必思"], 42, 0, 10, 0, [
            serving("1 bottle", 500, 420, 560),
            serving("1 cup", 240, 210, 270)
        ]),
        entry("Bibigo dumplings", ["bibigo dumplings", "bibigo mandu", "bibigo 왕교자"], 220, 8, 25, 9, [
            serving("6 pieces", 168, 126, 220),
            serving("10 pieces", 280, 210, 360),
            serving("1 piece", 28, 21, 36)
        ]),
        entry("Shin Ramyun", ["shin ramyun", "shin ramen", "辛拉面", "辛라면"], 145, 4.5, 22, 5.5, [
            serving("1 package", 520, 400, 700)
        ]),
        entry("Soju", ["soju", "소주", "烧酒", "韓國燒酒", "korean soju"], 134, 0, 0, 0, [
            serving("shot", 50, 40, 60),
            serving("glass", 50, 40, 75),
            serving("bottle", 360, 320, 380)
        ]),
        entry("Avocado", ["avocado", "牛油果", "鳄梨"], 160, 2, 8.5, 14.7, [
            serving("half avocado", 75, 55, 100),
            serving("1 avocado", 150, 120, 200)
        ]),
        entry("Banana", ["banana", "bananas", "香蕉"], 89, 1.1, 23, 0.3, [
            serving("1 banana", 118, 90, 150)
        ]),
        entry("Apple", ["apple", "apples", "苹果"], 52, 0.3, 14, 0.2, [
            serving("1 apple", 180, 140, 220)
        ]),
        entry("Oatmeal", ["oatmeal", "燕麦粥"], 68, 2.4, 12, 1.4, [
            serving("1 cup", 234, 180, 280),
            serving("bowl", 250, 180, 320)
        ]),
        entry("Dry oats", ["oats", "rolled oats", "old fashioned oats", "燕麦"], 389, 16.9, 66.3, 6.9, [
            serving("1/2 cup", 40, 32, 50),
            serving("1/4 cup", 20, 16, 28),
            serving("handful", 25, 15, 35)
        ]),
        entry("Overnight oats", ["overnight oats"], 120, 5, 18, 3, [
            serving("jar", 300, 240, 380),
            serving("bowl", 280, 220, 360)
        ]),
        entry("Granola", ["granola"], 471, 10, 64, 20, [
            serving("1/2 cup", 55, 40, 75),
            serving("1/4 cup", 28, 20, 38),
            serving("handful", 30, 20, 45)
        ]),
        entry("Peanut butter", ["peanut butter", "pb", "花生酱"], 588, 25, 20, 50, [
            serving("1 tbsp", 16, 12, 22),
            serving("spoonful", 20, 12, 30)
        ]),
        entry("Almond butter", ["almond butter"], 614, 21, 19, 56, [
            serving("1 tbsp", 16, 12, 22),
            serving("spoonful", 20, 12, 30)
        ]),
        entry("Salad", ["salad", "green salad", "沙拉"], 20, 1.2, 3.5, 0.2, [
            serving("bowl", 180, 100, 300),
            serving("plate", 240, 140, 360)
        ]),
        entry("Sweet potato", ["sweet potato", "yam", "红薯", "地瓜"], 86, 1.6, 20, 0.1, [
            serving("medium", 130, 100, 180)
        ]),
        entry("Tofu", ["tofu", "豆腐"], 144, 17, 3, 9, [
            serving("1 cup", 250, 200, 300),
            serving("serving", 150, 100, 220)
        ]),
        entry("Steak", ["steak", "牛排"], 271, 25, 0, 19, [
            serving("4 oz", 113, 90, 140)
        ]),
        entry("Turkey", ["turkey", "turkey breast", "火鸡"], 135, 29, 0, 1, [
            serving("serving", 113, 90, 140)
        ]),
        entry("Cottage cheese", ["cottage cheese", "茅屋奶酪"], 98, 11, 3.4, 4.3, [
            serving("1 cup", 226, 180, 260),
            serving("small bowl", 170, 140, 210)
        ]),
        entry("Protein shake", ["protein shake", "protein smoothie", "蛋白奶昔", "蛋白粉"], 48, 9, 1.5, 0.5, [
            serving("1 shake", 330, 250, 450),
            serving("1 scoop", 31, 25, 40)
        ]),
        entry("Smoothie bowl", ["smoothie bowl", "acai bowl", "açaí bowl"], 110, 2, 22, 2, [
            serving("bowl", 450, 330, 620),
            serving("small bowl", 320, 240, 430)
        ]),
        entry("Protein pancakes", ["protein pancakes", "protein pancake"], 190, 14, 22, 5, [
            serving("serving", 160, 120, 220),
            serving("2 pancakes", 140, 110, 190)
        ]),
        entry("Egg bites", ["egg bites", "egg white bites", "starbucks egg bites"], 170, 12, 9, 10, [
            serving("2 bites", 130, 110, 150),
            serving("serving", 130, 110, 150)
        ]),
        entry("Avocado toast", ["avocado toast", "avo toast"], 210, 6, 23, 11, [
            serving("1 slice", 120, 90, 170),
            serving("2 slices", 240, 180, 330)
        ]),
        entry("Milk", ["milk", "whole milk", "牛奶"], 61, 3.2, 4.8, 3.3, [
            serving("1 cup", 244, 220, 260)
        ]),
        entry("Oat milk", ["oat milk"], 50, 1, 6.7, 2, [
            serving("1 cup", 240, 220, 260),
            serving("1/2 cup", 120, 105, 135),
            serving("1/4 cup", 60, 50, 70),
            serving("1/8 cup", 30, 24, 38),
            serving("splash", 45, 20, 70)
        ]),
        entry("Almond milk", ["almond milk", "杏仁奶"], 15, 0.6, 0.3, 1.2, [
            serving("1 cup", 240, 220, 260)
        ]),
        entry("Matcha", ["matcha", "matcha latte"], 1, 0, 0, 0, [
            serving("1 cup", 240, 220, 300)
        ]),
        entry("Coffee", ["coffee", "espresso", "latte", "咖啡", "拿铁"], 1, 0.1, 0, 0, [
            serving("1 cup", 240, 180, 300)
        ]),
        entry("Cold brew", ["cold brew", "iced coffee"], 1, 0.1, 0, 0, [
            serving("medium", 475, 350, 600),
            serving("large", 590, 450, 720)
        ]),
        entry("Iced latte", ["iced latte", "latte with milk"], 45, 2.2, 4.2, 2, [
            serving("medium", 475, 350, 600),
            serving("large", 590, 450, 720)
        ]),
        entry("Oat milk latte", ["oat milk latte", "iced oat milk latte"], 62, 1.2, 8, 2.5, [
            serving("medium", 475, 350, 600),
            serving("large", 590, 450, 720)
        ]),
        entry("Vanilla latte", ["vanilla latte", "iced vanilla latte"], 74, 2.1, 11, 2, [
            serving("medium", 475, 350, 600),
            serving("large", 590, 450, 720)
        ]),
        entry("Broccoli", ["broccoli", "西兰花"], 35, 2.4, 7, 0.4, [
            serving("1 cup", 90, 70, 120)
        ]),
        entry("Toast", ["toast", "bread", "slice of toast", "吐司", "面包"], 265, 9, 49, 3.2, [
            serving("1 slice", 35, 28, 45)
        ]),
        entry("Chicken rice bowl", ["chicken rice bowl", "chicken bowl"], 150, 12, 17, 4, [
            serving("bowl", 450, 330, 620),
            serving("small bowl", 320, 240, 430)
        ]),
        entry("Burrito bowl", ["burrito bowl", "chipotle bowl"], 155, 9, 18, 5, [
            serving("bowl", 500, 380, 700)
        ]),
        entry("Poke bowl", ["poke bowl", "salmon poke", "tuna poke"], 140, 11, 18, 3.5, [
            serving("bowl", 500, 380, 680)
        ]),
        entry("Sushi roll", ["sushi", "sushi roll", "california roll", "salmon roll"], 145, 5, 26, 2, [
            serving("1 roll", 190, 150, 240),
            serving("6 pieces", 190, 150, 240)
        ]),
        entry("Salmon sashimi", ["salmon sashimi", "sashimi", "三文鱼刺身", "鮭魚刺身"], 208, 20, 0, 13, [
            serving("6 pieces", 120, 90, 160),
            serving("12 pieces", 240, 180, 320)
        ]),
        entry("Caesar salad", ["caesar salad", "chicken caesar"], 165, 9, 8, 11, [
            serving("bowl", 350, 250, 520),
            serving("plate", 420, 300, 620)
        ]),
        entry("Turkey sandwich", ["turkey sandwich", "turkey wrap"], 210, 15, 24, 6, [
            serving("sandwich", 220, 170, 300),
            serving("wrap", 240, 180, 320)
        ]),
        entry("Burger", ["burger", "cheeseburger"], 260, 15, 20, 14, [
            serving("1 burger", 230, 180, 320)
        ]),
        entry("Fries", ["fries", "french fries"], 312, 3.4, 41, 15, [
            serving("medium", 115, 90, 150),
            serving("small", 75, 55, 100)
        ])
    ]

    private static func entry(
        _ name: String,
        _ aliases: [String],
        _ calories: Double,
        _ protein: Double,
        _ carbs: Double,
        _ fat: Double,
        _ servings: [FoodServing]
    ) -> FoodNutritionEntry {
        FoodNutritionEntry(
            canonicalName: name,
            aliases: aliases,
            caloriesPer100g: calories,
            proteinPer100g: protein,
            carbsPer100g: carbs,
            fatPer100g: fat,
            commonServings: servings
        )
    }

    private static func serving(_ label: String, _ grams: Double, _ min: Double, _ max: Double) -> FoodServing {
        FoodServing(label: label, grams: grams, minGrams: min, maxGrams: max)
    }
}
