-- Michigan Dining Database Schema
-- =================================
--
-- This schema supports:
-- - Daily menu scraping and storage
-- - User rating system for food items
-- - Canonical food items for persistent ratings across days
-- - User preferences and dietary restrictions
--
-- Compatible with: PostgreSQL 12+ and SQLite 3.35+
--
-- Author: Auto-generated for Michigan Meals App
-- Date: 2025-10-22

-- ============================================
-- REFERENCE DATA & SCRAPING TABLES
-- ============================================

-- Dining Halls (reference table)
CREATE TABLE IF NOT EXISTS dining_halls (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    url TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Scrape Metadata (track each scrape run)
CREATE TABLE IF NOT EXISTS scrape_runs (
    id SERIAL PRIMARY KEY,
    dining_hall_id VARCHAR(50) REFERENCES dining_halls(id),
    menu_date DATE NOT NULL,
    scrape_timestamp TIMESTAMP NOT NULL,
    status VARCHAR(20) NOT NULL, -- 'success', 'partial', 'failed'
    items_scraped INTEGER DEFAULT 0,
    error_message TEXT,
    UNIQUE(dining_hall_id, menu_date)
);

-- Meal Periods (breakfast, lunch, dinner, brunch)
CREATE TABLE IF NOT EXISTS meal_periods (
    id SERIAL PRIMARY KEY,
    scrape_run_id INTEGER REFERENCES scrape_runs(id) ON DELETE CASCADE,
    meal_period VARCHAR(50) NOT NULL,  -- lowercase normalized (breakfast, lunch, dinner, brunch)
    meal_period_display VARCHAR(50) NOT NULL  -- original display text
);

-- Stations within meals
CREATE TABLE IF NOT EXISTS stations (
    id SERIAL PRIMARY KEY,
    meal_period_id INTEGER REFERENCES meal_periods(id) ON DELETE CASCADE,
    station_name VARCHAR(100) NOT NULL,
    display_order INTEGER DEFAULT 0
);

-- Food Items (daily menu instances)
CREATE TABLE IF NOT EXISTS food_items (
    id SERIAL PRIMARY KEY,
    station_id INTEGER REFERENCES stations(id) ON DELETE CASCADE,
    item_name VARCHAR(200) NOT NULL,
    display_order INTEGER DEFAULT 0,
    -- Link to persistent food item for ratings
    canonical_food_id INTEGER REFERENCES canonical_food_items(id)
);

-- Nutrition Facts
CREATE TABLE IF NOT EXISTS nutrition_facts (
    id SERIAL PRIMARY KEY,
    food_item_id INTEGER REFERENCES food_items(id) ON DELETE CASCADE,
    serving_size VARCHAR(100),
    calories INTEGER,
    total_fat VARCHAR(20),
    saturated_fat VARCHAR(20),
    trans_fat VARCHAR(20),
    cholesterol VARCHAR(20),
    sodium VARCHAR(20),
    total_carbohydrate VARCHAR(20),
    dietary_fiber VARCHAR(20),
    sugars VARCHAR(20),
    protein VARCHAR(20),
    vitamin_a VARCHAR(20),
    vitamin_c VARCHAR(20),
    calcium VARCHAR(20),
    iron VARCHAR(20)
);

-- Allergens (many-to-many relationship)
CREATE TABLE IF NOT EXISTS allergens (
    id SERIAL PRIMARY KEY,
    allergen_name VARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS food_item_allergens (
    food_item_id INTEGER REFERENCES food_items(id) ON DELETE CASCADE,
    allergen_id INTEGER REFERENCES allergens(id),
    PRIMARY KEY (food_item_id, allergen_id)
);

-- ============================================
-- RATING SYSTEM TABLES
-- ============================================

-- Canonical Food Items (persistent across days for ratings)
-- This represents the "concept" of a food item, regardless of when it's served
CREATE TABLE IF NOT EXISTS canonical_food_items (
    id SERIAL PRIMARY KEY,
    dining_hall_id VARCHAR(50) REFERENCES dining_halls(id),
    meal_period VARCHAR(50) NOT NULL,  -- breakfast, lunch, dinner, brunch
    station_name VARCHAR(100) NOT NULL,
    item_name VARCHAR(200) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_seen DATE,  -- Last date this item appeared on a menu
    -- Cached rating metrics (updated on each rating submission)
    average_rating DECIMAL(3,2) DEFAULT 0.0,
    total_ratings INTEGER DEFAULT 0,
    UNIQUE(dining_hall_id, meal_period, station_name, item_name)
);

-- Users (for authentication and ratings)
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL,
    auth_token_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP
);

-- User Ratings
CREATE TABLE IF NOT EXISTS user_ratings (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    canonical_food_id INTEGER REFERENCES canonical_food_items(id) ON DELETE CASCADE,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    review_text TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, canonical_food_id)  -- One rating per user per food item
);

-- User Preferences (for personalized recommendations)
CREATE TABLE IF NOT EXISTS user_preferences (
    user_id INTEGER PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    dietary_restrictions TEXT[],  -- Array: ['vegetarian', 'vegan', 'gluten_free']
    allergens TEXT[],  -- Array: ['nuts', 'dairy', 'shellfish']
    favorite_stations TEXT[],
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- INDEXES FOR PERFORMANCE
-- ============================================

-- Scraping indexes
CREATE INDEX IF NOT EXISTS idx_scrape_runs_date ON scrape_runs(menu_date);
CREATE INDEX IF NOT EXISTS idx_scrape_runs_dining_hall ON scrape_runs(dining_hall_id);
CREATE INDEX IF NOT EXISTS idx_food_items_name ON food_items(item_name);
CREATE INDEX IF NOT EXISTS idx_food_items_canonical ON food_items(canonical_food_id);

-- Rating indexes
CREATE INDEX IF NOT EXISTS idx_canonical_food_items_lookup ON canonical_food_items(dining_hall_id, meal_period, station_name, item_name);
CREATE INDEX IF NOT EXISTS idx_canonical_food_items_rating ON canonical_food_items(average_rating DESC, total_ratings DESC);
CREATE INDEX IF NOT EXISTS idx_canonical_food_items_last_seen ON canonical_food_items(last_seen);
CREATE INDEX IF NOT EXISTS idx_user_ratings_user ON user_ratings(user_id);
CREATE INDEX IF NOT EXISTS idx_user_ratings_food ON user_ratings(canonical_food_id);
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);

-- ============================================
-- SAMPLE DATA (Optional - for testing)
-- ============================================

-- Insert dining halls
INSERT INTO dining_halls (id, name, url) VALUES
    ('bursley', 'Bursley', 'https://dining.umich.edu/menus-locations/dining-halls/bursley/'),
    ('east-quad', 'East Quad', 'https://dining.umich.edu/menus-locations/dining-halls/east-quad/'),
    ('markley', 'Markley', 'https://dining.umich.edu/menus-locations/dining-halls/markley/'),
    ('mosher-jordan', 'Mosher Jordan', 'https://dining.umich.edu/menus-locations/dining-halls/mosher-jordan/'),
    ('north-quad', 'North Quad', 'https://dining.umich.edu/menus-locations/dining-halls/north-quad/'),
    ('south-quad', 'South Quad', 'https://dining.umich.edu/menus-locations/dining-halls/south-quad/'),
    ('twigs-at-oxford', 'Twigs at Oxford', 'https://dining.umich.edu/menus-locations/dining-halls/twigs-at-oxford/')
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- TRIGGERS (PostgreSQL only)
-- ============================================

-- Trigger to update average_rating when a new rating is added
-- This keeps the denormalized rating data in sync

-- CREATE OR REPLACE FUNCTION update_canonical_food_rating()
-- RETURNS TRIGGER AS $$
-- BEGIN
--     UPDATE canonical_food_items
--     SET
--         average_rating = (
--             SELECT AVG(rating)::DECIMAL(3,2)
--             FROM user_ratings
--             WHERE canonical_food_id = NEW.canonical_food_id
--         ),
--         total_ratings = (
--             SELECT COUNT(*)
--             FROM user_ratings
--             WHERE canonical_food_id = NEW.canonical_food_id
--         )
--     WHERE id = NEW.canonical_food_id;
--
--     RETURN NEW;
-- END;
-- $$ LANGUAGE plpgsql;
--
-- CREATE TRIGGER trigger_update_food_rating
--     AFTER INSERT OR UPDATE OR DELETE ON user_ratings
--     FOR EACH ROW
--     EXECUTE FUNCTION update_canonical_food_rating();

-- ============================================
-- USEFUL QUERIES
-- ============================================

-- Get top-rated items across all dining halls
-- SELECT
--     cf.item_name,
--     dh.name as dining_hall,
--     cf.station_name,
--     cf.average_rating,
--     cf.total_ratings
-- FROM canonical_food_items cf
-- JOIN dining_halls dh ON cf.dining_hall_id = dh.id
-- WHERE cf.total_ratings >= 10  -- Minimum rating threshold
-- ORDER BY cf.average_rating DESC, cf.total_ratings DESC
-- LIMIT 50;

-- Get today's menu with ratings
-- SELECT
--     dh.name as dining_hall,
--     mp.meal_period_display,
--     s.station_name,
--     fi.item_name,
--     cf.average_rating,
--     cf.total_ratings,
--     nf.calories,
--     nf.protein
-- FROM food_items fi
-- JOIN stations s ON fi.station_id = s.id
-- JOIN meal_periods mp ON s.meal_period_id = mp.id
-- JOIN scrape_runs sr ON mp.scrape_run_id = sr.id
-- JOIN dining_halls dh ON sr.dining_hall_id = dh.id
-- LEFT JOIN canonical_food_items cf ON fi.canonical_food_id = cf.id
-- LEFT JOIN nutrition_facts nf ON fi.id = nf.food_item_id
-- WHERE sr.menu_date = CURRENT_DATE
-- ORDER BY dh.name, mp.meal_period, s.station_name, fi.display_order;

-- Get user's ratings history
-- SELECT
--     cf.item_name,
--     dh.name as dining_hall,
--     cf.station_name,
--     ur.rating as user_rating,
--     cf.average_rating as community_rating,
--     ur.review_text,
--     ur.created_at
-- FROM user_ratings ur
-- JOIN canonical_food_items cf ON ur.canonical_food_id = cf.id
-- JOIN dining_halls dh ON cf.dining_hall_id = dh.id
-- WHERE ur.user_id = ?
-- ORDER BY ur.created_at DESC;
