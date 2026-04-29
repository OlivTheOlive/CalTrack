/// Maps a food display name to a single representative emoji using a
/// small keyword dictionary. Returns null when no rule matches so
/// callers can render a fallback (or nothing).
///
/// The list is intentionally compact and case-insensitive. Order is
/// significant: more specific matches (e.g. "ice cream") must come
/// before broader ones (e.g. "cream", "ice"). Keep entries short and
/// avoid stop-words to minimize accidental matches.
library;

const List<(String, String)> _foodEmojiRules = [
  // Compound names first so they win over single-word matches.
  ('ice cream', '🍨'),
  ('peanut butter', '🥜'),
  ('almond butter', '🥜'),
  ('whey protein', '🥤'),
  ('protein shake', '🥤'),
  ('protein bar', '🍫'),
  ('greek yogurt', '🥣'),
  ('cottage cheese', '🧀'),
  ('hot dog', '🌭'),
  ('french fries', '🍟'),
  ('mashed potato', '🥔'),
  ('sweet potato', '🍠'),
  ('whole wheat', '🍞'),
  ('whole grain', '🌾'),
  ('orange juice', '🧃'),
  ('coca cola', '🥤'),
  ('soda water', '🥤'),
  ('bell pepper', '🫑'),
  ('green onion', '🧅'),
  ('soy sauce', '🍶'),
  ('tomato sauce', '🍅'),
  ('olive oil', '🫒'),

  // Fruits.
  ('apple', '🍎'),
  ('banana', '🍌'),
  ('strawberr', '🍓'),
  ('blueberr', '🫐'),
  ('raspberr', '🍓'),
  ('blackberr', '🫐'),
  ('grape', '🍇'),
  ('orange', '🍊'),
  ('lemon', '🍋'),
  ('lime', '🍋'),
  ('mango', '🥭'),
  ('peach', '🍑'),
  ('pear', '🍐'),
  ('pineapple', '🍍'),
  ('watermelon', '🍉'),
  ('melon', '🍈'),
  ('cherry', '🍒'),
  ('cherries', '🍒'),
  ('kiwi', '🥝'),
  ('avocado', '🥑'),
  ('coconut', '🥥'),
  ('papaya', '🥭'),

  // Vegetables.
  ('tomato', '🍅'),
  ('potato', '🥔'),
  ('carrot', '🥕'),
  ('broccoli', '🥦'),
  ('cauliflower', '🥦'),
  ('cucumber', '🥒'),
  ('pickle', '🥒'),
  ('lettuce', '🥬'),
  ('spinach', '🥬'),
  ('kale', '🥬'),
  ('cabbage', '🥬'),
  ('corn', '🌽'),
  ('eggplant', '🍆'),
  ('mushroom', '🍄'),
  ('onion', '🧅'),
  ('garlic', '🧄'),
  ('pepper', '🫑'),
  ('zucchini', '🥒'),
  ('asparagus', '🥦'),
  ('green bean', '🫛'),
  ('peas', '🫛'),

  // Grains, legumes, nuts.
  ('rice', '🍚'),
  ('quinoa', '🌾'),
  ('oats', '🌾'),
  ('oatmeal', '🥣'),
  ('cereal', '🥣'),
  ('granola', '🥣'),
  ('barley', '🌾'),
  ('lentil', '🫘'),
  ('bean', '🫘'),
  ('chickpea', '🫘'),
  ('hummus', '🫘'),
  ('almond', '🥜'),
  ('walnut', '🥜'),
  ('cashew', '🥜'),
  ('pistachio', '🥜'),
  ('peanut', '🥜'),
  ('hazelnut', '🥜'),

  // Bread & baked goods.
  ('bread', '🍞'),
  ('toast', '🍞'),
  ('bagel', '🥯'),
  ('croissant', '🥐'),
  ('baguette', '🥖'),
  ('pancake', '🥞'),
  ('waffle', '🧇'),
  ('cookie', '🍪'),
  ('cake', '🍰'),
  ('donut', '🍩'),
  ('doughnut', '🍩'),
  ('muffin', '🧁'),
  ('cupcake', '🧁'),
  ('pretzel', '🥨'),

  // Meats & proteins.
  ('chicken', '🍗'),
  ('turkey', '🍗'),
  ('beef', '🥩'),
  ('steak', '🥩'),
  ('pork', '🥓'),
  ('bacon', '🥓'),
  ('ham', '🥓'),
  ('sausage', '🌭'),
  ('lamb', '🥩'),
  ('fish', '🐟'),
  ('salmon', '🐟'),
  ('tuna', '🐟'),
  ('shrimp', '🍤'),
  ('prawn', '🍤'),
  ('crab', '🦀'),
  ('lobster', '🦞'),
  ('egg', '🥚'),
  ('tofu', '🟦'),
  ('tempeh', '🟫'),

  // Dairy.
  ('milk', '🥛'),
  ('yogurt', '🥣'),
  ('cheese', '🧀'),
  ('butter', '🧈'),
  ('cream', '🥛'),

  // Prepared & meals.
  ('pizza', '🍕'),
  ('burger', '🍔'),
  ('sandwich', '🥪'),
  ('burrito', '🌯'),
  ('taco', '🌮'),
  ('pasta', '🍝'),
  ('spaghetti', '🍝'),
  ('noodle', '🍜'),
  ('ramen', '🍜'),
  ('sushi', '🍣'),
  ('soup', '🍲'),
  ('stew', '🍲'),
  ('curry', '🍛'),
  ('salad', '🥗'),
  ('omelet', '🍳'),
  ('omelette', '🍳'),

  // Drinks.
  ('coffee', '☕'),
  ('espresso', '☕'),
  ('latte', '☕'),
  ('tea', '🍵'),
  ('juice', '🧃'),
  ('smoothie', '🥤'),
  ('soda', '🥤'),
  ('cola', '🥤'),
  ('beer', '🍺'),
  ('wine', '🍷'),
  ('water', '💧'),

  // Sweets & condiments.
  ('chocolate', '🍫'),
  ('candy', '🍬'),
  ('honey', '🍯'),
  ('jam', '🍓'),
  ('jelly', '🍇'),
  ('syrup', '🍯'),
  ('sugar', '🍬'),
  ('salt', '🧂'),
];

/// Returns the most likely emoji for [foodName], or null when no rule
/// matches. Matching is case-insensitive and looks for substrings.
String? emojiForFood(String? foodName) {
  if (foodName == null) return null;
  final normalized = foodName.toLowerCase();
  if (normalized.isEmpty) return null;
  for (final (keyword, emoji) in _foodEmojiRules) {
    if (normalized.contains(keyword)) return emoji;
  }
  return null;
}
