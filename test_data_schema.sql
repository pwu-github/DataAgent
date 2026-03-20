-- ============================================================
-- 测试数据库建表 SQL
-- 适用于 Spring-AI-All 项目的 DataAgent 模块
-- 支持多表联合查询、数据分析、Python 数据处理及图表生成
-- ============================================================

-- 1. 用户表 (users)
CREATE TABLE IF NOT EXISTS users (
    user_id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '用户 ID',
    username VARCHAR(50) NOT NULL UNIQUE COMMENT '用户名',
    email VARCHAR(100) COMMENT '邮箱',
    phone VARCHAR(20) COMMENT '手机号',
    gender TINYINT DEFAULT 0 COMMENT '性别：0-未知，1-男，2-女',
    age INT COMMENT '年龄',
    city VARCHAR(50) COMMENT '城市',
    registration_date DATE COMMENT '注册日期',
    last_login_time DATETIME COMMENT '最后登录时间',
    status TINYINT DEFAULT 1 COMMENT '状态：0-禁用，1-正常',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间'
) COMMENT '用户信息表';

-- 2. 商品分类表 (categories)
CREATE TABLE IF NOT EXISTS categories (
    category_id INT PRIMARY KEY AUTO_INCREMENT COMMENT '分类 ID',
    category_name VARCHAR(100) NOT NULL COMMENT '分类名称',
    parent_id INT DEFAULT 0 COMMENT '父分类 ID',
    level INT DEFAULT 1 COMMENT '分类层级',
    sort_order INT DEFAULT 0 COMMENT '排序',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间'
) COMMENT '商品分类表';

-- 3. 商品表 (products)
CREATE TABLE IF NOT EXISTS products (
    product_id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '商品 ID',
    product_name VARCHAR(200) NOT NULL COMMENT '商品名称',
    category_id INT COMMENT '分类 ID',
    brand VARCHAR(100) COMMENT '品牌',
    price DECIMAL(10, 2) NOT NULL COMMENT '原价',
    cost_price DECIMAL(10, 2) COMMENT '成本价',
    stock_quantity INT DEFAULT 0 COMMENT '库存数量',
    description TEXT COMMENT '商品描述',
    status TINYINT DEFAULT 1 COMMENT '状态：0-下架，1-上架',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    FOREIGN KEY (category_id) REFERENCES categories(category_id)
) COMMENT '商品信息表';

-- 4. 订单表 (orders)
CREATE TABLE IF NOT EXISTS orders (
    order_id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '订单 ID',
    order_no VARCHAR(50) NOT NULL UNIQUE COMMENT '订单编号',
    user_id BIGINT NOT NULL COMMENT '用户 ID',
    order_amount DECIMAL(10, 2) NOT NULL COMMENT '订单金额',
    discount_amount DECIMAL(10, 2) DEFAULT 0 COMMENT '优惠金额',
    pay_amount DECIMAL(10, 2) NOT NULL COMMENT '实付金额',
    order_status TINYINT DEFAULT 0 COMMENT '订单状态：0-待支付，1-已支付，2-已发货，3-已完成，4-已取消',
    payment_method TINYINT COMMENT '支付方式：1-微信，2-支付宝，3-银行卡',
    payment_time DATETIME COMMENT '支付时间',
    shipping_address VARCHAR(500) COMMENT '收货地址',
    shipping_fee DECIMAL(10, 2) DEFAULT 0 COMMENT '运费',
    shipped_time DATETIME COMMENT '发货时间',
    completed_time DATETIME COMMENT '完成时间',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    INDEX idx_user_id (user_id),
    INDEX idx_order_status (order_status),
    INDEX idx_created_at (created_at),
    FOREIGN KEY (user_id) REFERENCES users(user_id)
) COMMENT '订单表';

-- 5. 订单明细表 (order_items)
CREATE TABLE IF NOT EXISTS order_items (
    item_id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '明细 ID',
    order_id BIGINT NOT NULL COMMENT '订单 ID',
    product_id BIGINT NOT NULL COMMENT '商品 ID',
    product_name VARCHAR(200) NOT NULL COMMENT '商品名称 (快照)',
    unit_price DECIMAL(10, 2) NOT NULL COMMENT '单价',
    quantity INT NOT NULL COMMENT '数量',
    subtotal DECIMAL(10, 2) NOT NULL COMMENT '小计金额',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    INDEX idx_order_id (order_id),
    INDEX idx_product_id (product_id),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
) COMMENT '订单明细表';

-- 6. 购物车表 (cart_items)
CREATE TABLE IF NOT EXISTS cart_items (
    cart_id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '购物车 ID',
    user_id BIGINT NOT NULL COMMENT '用户 ID',
    product_id BIGINT NOT NULL COMMENT '商品 ID',
    quantity INT DEFAULT 1 COMMENT '数量',
    checked TINYINT DEFAULT 0 COMMENT '是否勾选：0-未勾选，1-已勾选',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    UNIQUE KEY uk_user_product (user_id, product_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
) COMMENT '购物车表';

-- 7. 用户行为日志表 (user_actions)
CREATE TABLE IF NOT EXISTS user_actions (
    action_id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '行为 ID',
    user_id BIGINT COMMENT '用户 ID',
    action_type VARCHAR(50) NOT NULL COMMENT '行为类型：view-浏览，click-点击，cart-加购，favorite-收藏，search-搜索',
    target_id BIGINT COMMENT '目标 ID(商品 ID/分类 ID 等)',
    target_type VARCHAR(50) COMMENT '目标类型：product-商品，category-分类，search-搜索词',
    search_keyword VARCHAR(200) COMMENT '搜索关键词',
    device_type VARCHAR(20) COMMENT '设备类型：mobile-手机，pc-电脑，tablet-平板',
    ip_address VARCHAR(50) COMMENT 'IP 地址',
    action_time DATETIME NOT NULL COMMENT '行为时间',
    duration_seconds INT COMMENT '停留时长 (秒)',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    INDEX idx_user_id (user_id),
    INDEX idx_action_time (action_time),
    INDEX idx_action_type (action_type)
) COMMENT '用户行为日志表';

-- 8. 优惠券表 (coupons)
CREATE TABLE IF NOT EXISTS coupons (
    coupon_id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '优惠券 ID',
    coupon_name VARCHAR(100) NOT NULL COMMENT '优惠券名称',
    coupon_type TINYINT DEFAULT 1 COMMENT '类型：1-满减，2-折扣，3-无门槛',
    discount_value DECIMAL(10, 2) NOT NULL COMMENT '优惠额度/折扣率',
    min_purchase_amount DECIMAL(10, 2) COMMENT '最低消费金额',
    max_discount_amount DECIMAL(10, 2) COMMENT '最大优惠金额 (折扣券用)',
    total_count INT NOT NULL COMMENT '发放总量',
    issued_count INT DEFAULT 0 COMMENT '已发放数量',
    used_count INT DEFAULT 0 COMMENT '已使用数量',
    valid_from DATE NOT NULL COMMENT '有效期开始',
    valid_to DATE NOT NULL COMMENT '有效期结束',
    status TINYINT DEFAULT 1 COMMENT '状态：0-禁用，1-启用',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间'
) COMMENT '优惠券表';

-- 9. 用户优惠券表 (user_coupons)
CREATE TABLE IF NOT EXISTS user_coupons (
    user_coupon_id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '用户优惠券 ID',
    user_id BIGINT NOT NULL COMMENT '用户 ID',
    coupon_id BIGINT NOT NULL COMMENT '优惠券 ID',
    coupon_code VARCHAR(50) UNIQUE COMMENT '优惠券码',
    status TINYINT DEFAULT 0 COMMENT '状态：0-未使用，1-已使用，2-已过期',
    order_id BIGINT COMMENT '使用的订单 ID',
    used_time DATETIME COMMENT '使用时间',
    valid_from DATE NOT NULL COMMENT '有效期开始',
    valid_to DATE NOT NULL COMMENT '有效期结束',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    INDEX idx_user_id (user_id),
    INDEX idx_status (status),
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (coupon_id) REFERENCES coupons(coupon_id),
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
) COMMENT '用户优惠券表';

-- 10. 评价表 (reviews)
CREATE TABLE IF NOT EXISTS reviews (
    review_id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '评价 ID',
    order_id BIGINT NOT NULL COMMENT '订单 ID',
    user_id BIGINT NOT NULL COMMENT '用户 ID',
    product_id BIGINT NOT NULL COMMENT '商品 ID',
    rating TINYINT NOT NULL COMMENT '评分：1-5 星',
    content TEXT COMMENT '评价内容',
    images VARCHAR(1000) COMMENT '评价图片 (多张逗号分隔)',
    reply_content TEXT COMMENT '商家回复',
    reply_time DATETIME COMMENT '回复时间',
    is_anonymous TINYINT DEFAULT 0 COMMENT '是否匿名：0-否，1-是',
    helpful_count INT DEFAULT 0 COMMENT '有帮助的计数',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    INDEX idx_product_id (product_id),
    INDEX idx_user_id (user_id),
    INDEX idx_rating (rating),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
) COMMENT '商品评价表';

-- 11. 每日销售统计表 (daily_sales_summary) - 物化视图/统计表
CREATE TABLE IF NOT EXISTS daily_sales_summary (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT 'ID',
    stat_date DATE NOT NULL UNIQUE COMMENT '统计日期',
    total_orders INT DEFAULT 0 COMMENT '总订单数',
    paid_orders INT DEFAULT 0 COMMENT '已支付订单数',
    total_amount DECIMAL(12, 2) DEFAULT 0 COMMENT '总销售额',
    paid_amount DECIMAL(12, 2) DEFAULT 0 COMMENT '已支付金额',
    total_users INT DEFAULT 0 COMMENT '总用户数',
    new_users INT DEFAULT 0 COMMENT '新用户数',
    avg_order_value DECIMAL(10, 2) DEFAULT 0 COMMENT '客单价',
    top_category_id INT COMMENT '最热分类 ID',
    top_product_id BIGINT COMMENT '最热商品 ID',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间'
) COMMENT '每日销售统计汇总表';

-- 12. 用户画像统计表 (user_profile_stats)
CREATE TABLE IF NOT EXISTS user_profile_stats (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT 'ID',
    user_id BIGINT NOT NULL UNIQUE COMMENT '用户 ID',
    total_orders INT DEFAULT 0 COMMENT '总订单数',
    total_spent DECIMAL(12, 2) DEFAULT 0 COMMENT '总消费金额',
    avg_order_value DECIMAL(10, 2) DEFAULT 0 COMMENT '平均订单金额',
    favorite_category_id INT COMMENT '最常购买分类 ID',
    last_order_date DATE COMMENT '最后下单日期',
    days_since_registration INT COMMENT '注册天数',
    activity_score DECIMAL(5, 2) DEFAULT 0 COMMENT '活跃度评分',
    user_level VARCHAR(20) DEFAULT 'NORMAL' COMMENT '用户等级：VIP/NORMAL/LOW',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    FOREIGN KEY (user_id) REFERENCES users(user_id)
) COMMENT '用户画像统计表';

-- ============================================================
-- 测试数据插入语句
-- ============================================================

-- 插入用户数据
INSERT INTO users (username, email, phone, gender, age, city, registration_date, last_login_time, status) VALUES
('张三', 'zhangsan@example.com', '13800138001', 1, 28, '北京', '2024-01-15', '2024-03-19 10:30:00', 1),
('李四', 'lisi@example.com', '13800138002', 2, 32, '上海', '2024-02-10', '2024-03-18 15:45:00', 1),
('王五', 'wangwu@example.com', '13800138003', 1, 25, '广州', '2024-02-20', '2024-03-19 09:00:00', 1),
('赵六', 'zhaoliu@example.com', '13800138004', 2, 35, '深圳', '2024-03-01', '2024-03-17 20:00:00', 1),
('钱七', 'qianqi@example.com', '13800138005', 1, 22, '杭州', '2024-03-05', '2024-03-19 08:30:00', 1),
('孙八', 'sunba@example.com', '13800138006', 2, 29, '成都', '2024-03-10', '2024-03-18 12:00:00', 1),
('周九', 'zhoujiu@example.com', '13800138007', 1, 40, '武汉', '2024-01-20', '2024-03-16 18:00:00', 1),
('吴十', 'wushi@example.com', '13800138008', 2, 27, '西安', '2024-02-28', '2024-03-19 11:00:00', 1);

-- 插入商品分类数据
INSERT INTO categories (category_name, parent_id, level, sort_order) VALUES
('电子产品', 0, 1, 1),
('手机数码', 1, 2, 1),
('电脑办公', 1, 2, 2),
('智能穿戴', 1, 2, 3),
('服装鞋帽', 0, 1, 2),
('男装', 5, 2, 1),
('女装', 5, 2, 2),
('运动鞋服', 0, 1, 3),
('食品饮料', 0, 1, 4),
('生鲜水果', 9, 2, 1),
('休闲零食', 9, 2, 2),
('家居日用', 0, 1, 5);

-- 插入商品数据
INSERT INTO products (product_name, category_id, brand, price, cost_price, stock_quantity, description, status) VALUES
('iPhone 15 Pro', 2, 'Apple', 7999.00, 6500.00, 500, '最新款 iPhone，A17 Pro 芯片', 1),
('MacBook Pro 14', 3, 'Apple', 12999.00, 10500.00, 200, 'M3 Pro 芯片，18GB 内存', 1),
('AirPods Pro 2', 4, 'Apple', 1899.00, 1200.00, 1000, '主动降噪无线蓝牙耳机', 1),
('华为 Mate 60 Pro', 2, '华为', 6999.00, 5500.00, 800, '卫星通话，鸿蒙系统', 1),
('小米 14 Ultra', 2, '小米', 5999.00, 4800.00, 600, '徕卡光学镜头，骁龙 8Gen3', 1),
('ThinkPad X1 Carbon', 3, '联想', 9999.00, 8000.00, 150, '14 英寸轻薄商务笔记本', 1),
('Apple Watch S9', 4, 'Apple', 2999.00, 2200.00, 400, '智能手表，血氧检测', 1),
('华为 Watch GT4', 4, '华为', 1688.00, 1100.00, 600, '长续航智能手表', 1),
('男士休闲夹克', 6, '优衣库', 399.00, 180.00, 2000, '春秋款修身夹克', 1),
('女士连衣裙', 7, 'ZARA', 299.00, 120.00, 1500, '夏季新款碎花连衣裙', 1),
('耐克 Air Max 运动鞋', 8, 'Nike', 899.00, 450.00, 800, '气垫减震跑步鞋', 1),
('进口车厘子 5 斤装', 10, '鲜丰', 299.00, 200.00, 300, '智利进口 JJ 级大果', 1),
('三只松鼠坚果礼盒', 11, '三只松鼠', 168.00, 100.00, 5000, '每日坚果混合装', 1),
('乳胶床垫 1.8m', 12, '睡眠博士', 1999.00, 1200.00, 100, '泰国天然乳胶', 1);

-- 插入订单数据
INSERT INTO orders (order_no, user_id, order_amount, discount_amount, pay_amount, order_status, payment_method, payment_time, shipping_address, shipping_fee, shipped_time, completed_time) VALUES
('ORD202403150001', 1, 7999.00, 0, 7999.00, 3, 1, '2024-03-15 10:35:00', '北京市朝阳区 xx 路 xx 号', 0, '2024-03-15 14:00:00', '2024-03-17 09:00:00'),
('ORD202403150002', 2, 1899.00, 100, 1799.00, 3, 2, '2024-03-15 11:20:00', '上海市浦东新区 xx 路 xx 号', 0, '2024-03-15 16:00:00', '2024-03-18 10:00:00'),
('ORD202403160001', 3, 5999.00, 200, 5799.00, 3, 1, '2024-03-16 09:15:00', '广州市天河区 xx 路 xx 号', 0, '2024-03-16 15:00:00', '2024-03-19 11:00:00'),
('ORD202403160002', 1, 399.00, 0, 399.00, 3, 1, '2024-03-16 14:30:00', '北京市朝阳区 xx 路 xx 号', 10, '2024-03-17 10:00:00', '2024-03-19 09:00:00'),
('ORD202403170001', 4, 12999.00, 500, 12499.00, 2, 3, '2024-03-17 16:00:00', '深圳市南山区 xx 路 xx 号', 0, '2024-03-18 10:00:00', NULL),
('ORD202403170002', 5, 899.00, 0, 899.00, 3, 2, '2024-03-17 10:00:00', '杭州市西湖区 xx 路 xx 号', 0, '2024-03-17 14:00:00', '2024-03-19 08:00:00'),
('ORD202403180001', 2, 299.00, 0, 299.00, 3, 1, '2024-03-18 11:30:00', '上海市浦东新区 xx 路 xx 号', 0, '2024-03-18 15:00:00', '2024-03-19 14:00:00'),
('ORD202403180002', 6, 299.00, 50, 249.00, 1, 1, '2024-03-18 14:00:00', '成都市武侯区 xx 路 xx 号', 0, NULL, NULL),
('ORD202403190001', 7, 1688.00, 100, 1588.00, 0, NULL, NULL, '武汉市江汉区 xx 路 xx 号', 0, NULL, NULL),
('ORD202403190002', 8, 6999.00, 300, 6699.00, 1, 2, '2024-03-19 09:30:00', '西安市雁塔区 xx 路 xx 号', 0, NULL, NULL);

-- 插入订单明细数据
INSERT INTO order_items (order_id, product_id, product_name, unit_price, quantity, subtotal) VALUES
(1, 1, 'iPhone 15 Pro', 7999.00, 1, 7999.00),
(2, 3, 'AirPods Pro 2', 1899.00, 1, 1899.00),
(3, 5, '小米 14 Ultra', 5999.00, 1, 5999.00),
(4, 9, '男士休闲夹克', 399.00, 1, 399.00),
(5, 2, 'MacBook Pro 14', 12999.00, 1, 12999.00),
(6, 11, '耐克 Air Max 运动鞋', 899.00, 1, 899.00),
(7, 10, '女士连衣裙', 299.00, 1, 299.00),
(8, 12, '进口车厘子 5 斤装', 299.00, 1, 299.00),
(9, 8, '华为 Watch GT4', 1688.00, 1, 1688.00),
(10, 4, '华为 Mate 60 Pro', 6999.00, 1, 6999.00);

-- 插入用户行为数据
INSERT INTO user_actions (user_id, action_type, target_id, target_type, search_keyword, device_type, ip_address, action_time, duration_seconds) VALUES
(1, 'view', 1, 'product', NULL, 'mobile', '192.168.1.100', '2024-03-15 09:00:00', 120),
(1, 'cart', 1, 'product', NULL, 'mobile', '192.168.1.100', '2024-03-15 09:05:00', NULL),
(1, 'click', 1, 'product', NULL, 'mobile', '192.168.1.100', '2024-03-15 10:30:00', NULL),
(2, 'search', NULL, 'search', '耳机', 'pc', '192.168.1.101', '2024-03-15 10:00:00', NULL),
(2, 'view', 3, 'product', NULL, 'pc', '192.168.1.101', '2024-03-15 10:05:00', 180),
(2, 'favorite', 3, 'product', NULL, 'pc', '192.168.1.101', '2024-03-15 10:10:00', NULL),
(3, 'view', 5, 'product', NULL, 'mobile', '192.168.1.102', '2024-03-16 08:00:00', 90),
(3, 'view', 4, 'product', NULL, 'mobile', '192.168.1.102', '2024-03-16 08:05:00', 60),
(3, 'cart', 5, 'product', NULL, 'mobile', '192.168.1.102', '2024-03-16 09:00:00', NULL),
(4, 'view', 2, 'product', NULL, 'tablet', '192.168.1.103', '2024-03-17 14:00:00', 300),
(4, 'click', 2, 'product', NULL, 'tablet', '192.168.1.103', '2024-03-17 15:30:00', NULL),
(5, 'search', NULL, 'search', '运动鞋', 'mobile', '192.168.1.104', '2024-03-17 09:00:00', NULL),
(5, 'view', 11, 'product', NULL, 'mobile', '192.168.1.104', '2024-03-17 09:05:00', 45),
(6, 'view', 12, 'product', NULL, 'mobile', '192.168.1.105', '2024-03-18 13:00:00', 60),
(6, 'cart', 12, 'product', NULL, 'mobile', '192.168.1.105', '2024-03-18 13:30:00', NULL),
(7, 'view', 8, 'product', NULL, 'pc', '192.168.1.106', '2024-03-19 08:00:00', 150),
(8, 'search', NULL, 'search', '手机', 'mobile', '192.168.1.107', '2024-03-19 09:00:00', NULL),
(8, 'view', 4, 'product', NULL, 'mobile', '192.168.1.107', '2024-03-19 09:10:00', 200);

-- 插入优惠券数据
INSERT INTO coupons (coupon_name, coupon_type, discount_value, min_purchase_amount, max_discount_amount, total_count, issued_count, used_count, valid_from, valid_to, status) VALUES
('新人专享券', 3, 50.00, 0, NULL, 10000, 8500, 6000, '2024-01-01', '2024-12-31', 1),
('满 1000 减 100', 1, 100.00, 1000.00, NULL, 5000, 3200, 2800, '2024-03-01', '2024-03-31', 1),
('满 5000 减 500', 1, 500.00, 5000.00, NULL, 1000, 450, 380, '2024-03-01', '2024-03-31', 1),
('8 折折扣券', 2, 0.8, 0, 200.00, 2000, 1500, 1200, '2024-03-15', '2024-04-15', 1),
('3C 数码专享券', 1, 200.00, 2000.00, NULL, 3000, 2100, 1800, '2024-03-10', '2024-03-25', 1);

-- 插入用户优惠券数据
INSERT INTO user_coupons (user_id, coupon_id, coupon_code, status, order_id, used_time, valid_from, valid_to) VALUES
(1, 2, 'CP2024031501', 1, 1, '2024-03-15 10:35:00', '2024-03-01', '2024-03-31'),
(2, 1, 'CP2024031502', 0, NULL, NULL, '2024-01-01', '2024-12-31'),
(2, 4, 'CP2024031503', 1, 2, '2024-03-15 11:20:00', '2024-03-15', '2024-04-15'),
(3, 5, 'CP2024031601', 1, 3, '2024-03-16 09:15:00', '2024-03-10', '2024-03-25'),
(4, 3, 'CP2024031701', 0, NULL, NULL, '2024-03-01', '2024-03-31'),
(5, 1, 'CP2024031702', 0, NULL, NULL, '2024-01-01', '2024-12-31'),
(6, 4, 'CP2024031801', 0, NULL, NULL, '2024-03-15', '2024-04-15'),
(8, 5, 'CP2024031901', 0, NULL, NULL, '2024-03-10', '2024-03-25');

-- 插入评价数据
INSERT INTO reviews (order_id, user_id, product_id, rating, content, images, reply_content, reply_time, is_anonymous, helpful_count) VALUES
(1, 1, 1, 5, '非常好用，系统流畅，拍照效果出色！', 'img1.jpg,img2.jpg', '感谢您的支持！', '2024-03-17 10:00:00', 0, 25),
(2, 2, 3, 4, '降噪效果不错，佩戴舒适，但价格稍高', NULL, '感谢您的反馈，我们会继续努力！', '2024-03-18 11:00:00', 0, 12),
(3, 3, 5, 5, '徕卡镜头真的很强，拍照效果满意', 'img3.jpg', NULL, NULL, 0, 8),
(4, 1, 9, 4, '质量不错，穿着舒适，尺码标准', NULL, NULL, NULL, 0, 5),
(6, 5, 11, 5, '鞋子很轻便，跑步很舒服，值得购买', 'img4.jpg,img5.jpg', '感谢选择耐克！', '2024-03-18 09:00:00', 0, 15),
(7, 2, 10, 3, '款式还可以，但面料感觉一般', NULL, NULL, NULL, 0, 3);

-- 插入每日销售统计数据
INSERT INTO daily_sales_summary (stat_date, total_orders, paid_orders, total_amount, paid_amount, total_users, new_users, avg_order_value, top_category_id, top_product_id) VALUES
('2024-03-15', 2, 2, 9898.00, 9798.00, 2, 0, 4899.00, 2, 1),
('2024-03-16', 2, 2, 6398.00, 6198.00, 2, 0, 3099.00, 2, 5),
('2024-03-17', 2, 1, 13898.00, 12499.00, 2, 0, 12499.00, 3, 2),
('2024-03-18', 2, 1, 598.00, 249.00, 2, 0, 249.00, 7, 10),
('2024-03-19', 2, 0, 8687.00, 0.00, 2, 0, 0.00, 4, 4);

-- 插入用户画像统计数据
INSERT INTO user_profile_stats (user_id, total_orders, total_spent, avg_order_value, favorite_category_id, last_order_date, days_since_registration, activity_score, user_level) VALUES
(1, 2, 8398.00, 4199.00, 2, '2024-03-16', 64, 85.50, 'VIP'),
(2, 2, 2098.00, 1049.00, 7, '2024-03-18', 38, 65.30, 'NORMAL'),
(3, 1, 5799.00, 5799.00, 2, '2024-03-16', 28, 55.00, 'NORMAL'),
(4, 1, 12499.00, 12499.00, 3, '2024-03-17', 19, 75.00, 'VIP'),
(5, 1, 899.00, 899.00, 8, '2024-03-17', 15, 45.00, 'NORMAL'),
(6, 1, 249.00, 249.00, 10, '2024-03-18', 10, 35.00, 'LOW'),
(7, 1, 1588.00, 1588.00, 4, '2024-03-19', 59, 40.00, 'NORMAL'),
(8, 1, 6699.00, 6699.00, 2, '2024-03-19', 20, 50.00, 'NORMAL');

-- ============================================================
-- 常用分析查询示例
-- ============================================================

-- 查询 1: 多表联查 - 用户订单详情
-- SELECT u.username, o.order_no, o.pay_amount, o.order_status, p.product_name, oi.quantity
-- FROM users u
-- JOIN orders o ON u.user_id = o.user_id
-- JOIN order_items oi ON o.order_id = oi.order_id
-- JOIN products p ON oi.product_id = p.product_id
-- ORDER BY o.created_at DESC;

-- 查询 2: 销售分析 - 按分类统计销售额
-- SELECT c.category_name, SUM(oi.subtotal) as total_sales, COUNT(oi.item_id) as total_items
-- FROM order_items oi
-- JOIN products p ON oi.product_id = p.product_id
-- JOIN categories c ON p.category_id = c.category_id
-- GROUP BY c.category_id, c.category_name
-- ORDER BY total_sales DESC;

-- 查询 3: 用户行为分析 - 各类型行为数量
-- SELECT action_type, COUNT(*) as action_count, COUNT(DISTINCT user_id) as unique_users
-- FROM user_actions
-- GROUP BY action_type
-- ORDER BY action_count DESC;

-- 查询 4: 优惠券使用率分析
-- SELECT c.coupon_name, c.total_count, c.issued_count, c.used_count,
--        ROUND(c.used_count * 100.0 / c.issued_count, 2) as usage_rate
-- FROM coupons c
-- ORDER BY usage_rate DESC;

-- 查询 5: 商品评价统计
-- SELECT p.product_name, AVG(r.rating) as avg_rating, COUNT(r.review_id) as review_count
-- FROM products p
-- LEFT JOIN reviews r ON p.product_id = r.product_id
-- GROUP BY p.product_id, p.product_name
-- HAVING review_count > 0
-- ORDER BY avg_rating DESC;