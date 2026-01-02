import '../models/article_model.dart';

class ArticleService {
  List<Article> get allArticles => _articles;

  final List<Article> _articles = [
    // Heart Health Articles
    Article(
      id: '1',
      title: 'Understanding High Blood Pressure',
      content: '''High blood pressure, also known as hypertension, is a common condition that affects millions of people worldwide. It occurs when the force of blood against your artery walls is consistently too high.

What is Blood Pressure?
Blood pressure is measured in millimeters of mercury (mmHg) and consists of two numbers:
- Systolic pressure (top number): Pressure when your heart beats
- Diastolic pressure (bottom number): Pressure when your heart rests between beats

Normal blood pressure is less than 120/80 mmHg. High blood pressure is 130/80 mmHg or higher.

Causes of High Blood Pressure:
- Poor diet (high in salt, fat, and cholesterol)
- Lack of physical activity
- Obesity
- Smoking and excessive alcohol consumption
- Stress
- Family history
- Age (risk increases with age)

Symptoms:
High blood pressure is often called the "silent killer" because it usually has no symptoms. Regular check-ups are essential.

Prevention and Management:
- Maintain a healthy weight
- Exercise regularly (at least 150 minutes per week)
- Eat a balanced diet rich in fruits, vegetables, and whole grains
- Reduce salt intake
- Limit alcohol and quit smoking
- Manage stress through relaxation techniques
- Take medications as prescribed by your doctor

Regular monitoring and lifestyle changes can help control high blood pressure and reduce the risk of heart disease, stroke, and other complications.''',
      category: 'Heart Health',
      readTime: '5 min read',
      author: 'Dr. Sarah Johnson',
      publishDate: DateTime(2024, 1, 1),
      imageUrl: 'https://via.placeholder.com/400x200?text=Heart+Health', // Placeholder - add actual image to assets/images/
      tags: ['blood pressure', 'hypertension', 'cardiovascular', 'prevention'],
    ),

    Article(
      id: '2',
      title: 'Heart-Healthy Eating: The DASH Diet',
      content: '''The DASH (Dietary Approaches to Stop Hypertension) diet is a proven eating plan designed to help treat or prevent high blood pressure. This diet emphasizes fruits, vegetables, whole grains, and lean proteins while reducing salt, saturated fats, and added sugars.

Key Principles of the DASH Diet:

1. Emphasize Vegetables and Fruits
   - Aim for 4-5 servings of vegetables daily
   - Include 4-5 servings of fruits daily
   - These provide potassium, magnesium, and fiber

2. Choose Whole Grains
   - At least 6-8 servings per day
   - Include whole wheat bread, brown rice, oats, and quinoa

3. Include Lean Proteins
   - Fish, poultry, beans, and nuts
   - Limit red meat to 6 ounces or less per day

4. Low-Fat Dairy Products
   - 2-3 servings daily
   - Choose low-fat or fat-free options

5. Healthy Fats
   - Use olive oil, avocados, and nuts in moderation

6. Reduce Sodium
   - Limit to 2,300 mg per day (ideally 1,500 mg)
   - Avoid processed foods and added salt

Sample Daily Menu:
- Breakfast: Oatmeal with berries and low-fat milk
- Lunch: Grilled chicken salad with mixed vegetables
- Dinner: Baked salmon with quinoa and steamed broccoli
- Snacks: Apple with almonds, carrot sticks with hummus

Benefits:
- Can lower blood pressure within 2 weeks
- Reduces risk of heart disease, stroke, and diabetes
- Helps with weight management
- Improves overall nutrition

The DASH diet is flexible and can be adapted to different cultures and preferences. Consult with a healthcare provider before making significant dietary changes.''',
      category: 'Heart Health',
      readTime: '6 min read',
      author: 'Dr. Michael Chen',
      publishDate: DateTime(2024, 1, 2),
      imageUrl: 'https://via.placeholder.com/400x200?text=DASH+Diet', // Placeholder - add actual image to assets/images/
      tags: ['diet', 'nutrition', 'DASH', 'heart healthy', 'blood pressure'],
    ),

    // Mental Wellness Articles
    Article(
      id: '3',
      title: 'Managing Stress in Daily Life',
      content: '''Stress is a natural response to challenging situations, but chronic stress can negatively impact your physical and mental health. Learning to manage stress effectively is crucial for maintaining overall well-being.

Understanding Stress:
Stress is your body's reaction to any demand or threat. In small doses, stress can be motivating and help you perform better. However, ongoing stress can lead to health problems.

Common Causes of Stress:
- Work pressure and deadlines
- Financial concerns
- Relationship issues
- Health problems
- Major life changes
- Daily hassles and responsibilities

Signs of Chronic Stress:
- Physical: Headaches, muscle tension, fatigue, sleep problems
- Emotional: Anxiety, irritability, depression, mood swings
- Behavioral: Overeating, undereating, substance abuse
- Cognitive: Difficulty concentrating, memory problems, negative thinking

Effective Stress Management Techniques:

1. Exercise Regularly
   - Physical activity releases endorphins that improve mood
   - Aim for 30 minutes of moderate exercise most days

2. Practice Relaxation Techniques
   - Deep breathing exercises
   - Progressive muscle relaxation
   - Meditation and mindfulness

3. Maintain Healthy Habits
   - Get adequate sleep (7-9 hours per night)
   - Eat nutritious meals
   - Limit caffeine and alcohol

4. Time Management
   - Prioritize tasks
   - Break large projects into smaller steps
   - Learn to say "no" when necessary

5. Social Support
   - Talk to friends and family
   - Join support groups
   - Seek professional help when needed

6. Cognitive Techniques
   - Challenge negative thoughts
   - Practice positive self-talk
   - Use humor to lighten situations

When to Seek Professional Help:
- Stress is interfering with daily life
- Physical symptoms persist
- Feelings of depression or anxiety are overwhelming
- Thoughts of self-harm

Remember, stress is manageable. Small changes in daily habits can make a significant difference in how you handle life's challenges.''',
      category: 'Mental Wellness',
      readTime: '7 min read',
      author: 'Dr. Priya Sharma',
      publishDate: DateTime(2024, 1, 3),
      imageUrl: 'https://via.placeholder.com/400x200?text=Stress+Management', // Placeholder - add actual image to assets/images/
      tags: ['stress', 'mental health', 'wellness', 'coping', 'relaxation'],
    ),

    Article(
      id: '4',
      title: 'The Benefits of Mindfulness Meditation',
      content: '''Mindfulness meditation is a mental training practice that teaches you to slow down racing thoughts, let go of negativity, and calm both your mind and body. This ancient practice has been scientifically proven to provide numerous health benefits.

What is Mindfulness?
Mindfulness is the practice of being fully present and engaged in the current moment, without judgment. It involves paying attention to your thoughts, feelings, and sensations in a gentle, accepting way.

How to Practice Mindfulness Meditation:

1. Find a Quiet Space
   - Choose a comfortable, distraction-free environment
   - Sit or lie down in a comfortable position

2. Focus on Your Breath
   - Pay attention to the sensation of breathing
   - Notice the rise and fall of your chest or belly

3. Acknowledge Thoughts
   - When your mind wanders, gently bring it back to your breath
   - Don't judge or criticize yourself

4. Start Small
   - Begin with 5-10 minutes daily
   - Gradually increase duration as you become more comfortable

Scientific Benefits of Mindfulness:

Mental Health Benefits:
- Reduces symptoms of anxiety and depression
- Improves emotional regulation
- Enhances self-awareness
- Increases resilience to stress

Physical Health Benefits:
- Lowers blood pressure
- Improves sleep quality
- Reduces chronic pain
- Boosts immune function

Cognitive Benefits:
- Improves attention and concentration
- Enhances memory and learning
- Increases creativity
- Better decision-making

Different Types of Mindfulness Meditation:

1. Body Scan Meditation
   - Systematically focus attention on different parts of the body

2. Loving-Kindness Meditation
   - Cultivate feelings of compassion and love for yourself and others

3. Walking Meditation
   - Practice mindfulness while walking slowly and deliberately

4. Mindful Eating
   - Pay full attention to the experience of eating

Tips for Success:
- Be consistent with your practice
- Be patient and kind to yourself
- Use guided meditations when starting out
- Practice mindfulness in daily activities (eating, walking, etc.)

Mindfulness is a skill that improves with practice. Even a few minutes a day can make a significant difference in your quality of life.''',
      category: 'Mental Wellness',
      readTime: '6 min read',
      author: 'Dr. David Kim',
      publishDate: DateTime(2024, 1, 4),
      imageUrl: 'https://via.placeholder.com/400x200?text=Mindfulness', // Placeholder - add actual image to assets/images/
      tags: ['meditation', 'mindfulness', 'mental health', 'stress relief', 'wellness'],
    ),

    // Nutrition Articles
    Article(
      id: '5',
      title: 'Balanced Nutrition for Optimal Health',
      content: '''Proper nutrition is essential for maintaining good health, preventing disease, and supporting optimal body function. A balanced diet provides the nutrients your body needs to thrive.

Essential Nutrients:

Macronutrients:
- Carbohydrates: Primary energy source (45-65% of daily calories)
- Proteins: Building blocks for tissues (10-35% of daily calories)
- Fats: Essential for hormone production and nutrient absorption (20-35% of daily calories)

Micronutrients:
- Vitamins: Organic compounds needed in small amounts
- Minerals: Inorganic elements essential for various functions
- Water: Makes up about 60% of body weight

Building a Balanced Plate:

1. Fill Half Your Plate with Vegetables and Fruits
   - Aim for variety in color and type
   - Include leafy greens, cruciferous vegetables, and colorful produce
   - Provides fiber, vitamins, and antioxidants

2. Add Lean Protein
   - Choose fish, poultry, beans, tofu, or nuts
   - Include eggs and low-fat dairy for variety
   - Supports muscle maintenance and immune function

3. Include Whole Grains
   - Brown rice, quinoa, oats, and whole wheat products
   - Provide sustained energy and fiber

4. Don't Forget Healthy Fats
   - Avocados, nuts, seeds, and olive oil
   - Support brain health and hormone production

5. Stay Hydrated
   - Drink water throughout the day
   - Herbal teas and infused water add variety

Meal Planning Tips:
- Plan meals and snacks ahead of time
- Prepare meals at home when possible
- Read nutrition labels
- Practice portion control
- Listen to your body's hunger and fullness cues

Special Considerations:
- Age and life stage affect nutritional needs
- Physical activity level influences calorie requirements
- Medical conditions may require dietary modifications
- Consult healthcare providers for personalized advice

Common Nutrition Myths:
- All fats are bad (healthy fats are essential)
- Carbohydrates should be avoided (complex carbs are important)
- Supplements can replace a healthy diet
- Detox diets are necessary for health

Remember, nutrition is highly individual. What works for one person may not work for another. Focus on whole, unprocessed foods and enjoy your meals mindfully.''',
      category: 'Nutrition',
      readTime: '8 min read',
      author: 'Dr. Lisa Rodriguez',
      publishDate: DateTime(2024, 1, 5),
      imageUrl: 'https://via.placeholder.com/400x200?text=Balanced+Nutrition', // Placeholder - add actual image to assets/images/
      tags: ['nutrition', 'diet', 'healthy eating', 'balanced diet', 'nutrients'],
    ),

    // Fitness Articles
    Article(
      id: '6',
      title: 'Starting a Safe Exercise Routine',
      content: '''Regular physical activity is one of the most important things you can do for your health. However, starting an exercise routine requires careful planning to ensure safety and sustainability.

Benefits of Regular Exercise:
- Improves cardiovascular health
- Strengthens bones and muscles
- Helps maintain healthy weight
- Boosts mood and mental health
- Improves sleep quality
- Reduces risk of chronic diseases

Assessing Your Fitness Level:
Before starting, evaluate your current fitness level:
- How active are you currently?
- Do you have any health conditions?
- What are your fitness goals?
- How much time can you dedicate?

Consulting Healthcare Providers:
- Talk to your doctor before starting a new exercise program
- Especially important if you have chronic conditions
- Get clearance for high-intensity activities
- Discuss any medications that might affect exercise

Creating a Safe Exercise Plan:

1. Set Realistic Goals
   - Start small and build gradually
   - Focus on consistency over intensity
   - Include variety to prevent boredom

2. Choose Activities You Enjoy
   - Walking, swimming, cycling, dancing
   - Team sports, yoga, martial arts
   - Home workouts or gym sessions

3. Follow the FITT Principle
   - Frequency: How often you exercise
   - Intensity: How hard you work
   - Time: How long each session lasts
   - Type: What kind of activity you do

4. Warm Up and Cool Down
   - 5-10 minutes of light activity before exercising
   - Gentle stretching after workouts
   - Helps prevent injuries

5. Listen to Your Body
   - Stop if you feel pain (beyond normal muscle fatigue)
   - Rest when needed
   - Stay hydrated
   - Get adequate sleep

Sample Beginner Routine:
- Monday: 30-minute brisk walk
- Tuesday: Light strength training (bodyweight exercises)
- Wednesday: Rest or gentle yoga
- Thursday: 30-minute walk or swim
- Friday: Strength training
- Saturday: Longer walk or recreational activity
- Sunday: Rest

Progression and Modification:
- Gradually increase duration and intensity
- Add new activities as you improve
- Modify exercises for any limitations
- Track your progress and celebrate achievements

Staying Motivated:
- Find an exercise buddy
- Set rewards for milestones
- Track your activities
- Join fitness classes or online communities
- Remember why you started

Remember, any movement is better than no movement. Start where you are, be patient with yourself, and enjoy the journey to better health.''',
      category: 'Fitness & Exercise',
      readTime: '7 min read',
      author: 'Coach James Wilson',
      publishDate: DateTime(2024, 1, 6),
      imageUrl: 'https://via.placeholder.com/400x200?text=Exercise+Routine', // Placeholder - add actual image to assets/images/
      tags: ['exercise', 'fitness', 'workout', 'beginner', 'health'],
    ),

    // Vaccination Articles
    Article(
      id: '7',
      title: 'Understanding Vaccine Safety and Efficacy',
      content: '''Vaccines are one of the most effective tools for preventing infectious diseases. Understanding how vaccines work and their safety profile can help you make informed decisions about vaccination.

How Vaccines Work:
Vaccines teach your immune system to recognize and fight specific pathogens without causing the disease. They contain weakened, inactivated, or parts of the disease-causing organism.

Types of Vaccines:
- Live attenuated vaccines: Contain weakened live virus
- Inactivated vaccines: Contain killed virus
- Subunit vaccines: Contain only specific parts of the pathogen
- mRNA vaccines: Teach cells to make harmless protein pieces

Vaccine Safety:
Vaccines undergo rigorous testing before approval:
- Pre-clinical testing in laboratories
- Phase 1: Small group safety testing
- Phase 2: Larger group efficacy testing
- Phase 3: Large-scale effectiveness and safety studies
- Ongoing monitoring after approval

Safety Monitoring Systems:
- Vaccine Adverse Event Reporting System (VAERS)
- Vaccine Safety Datalink
- Clinical Immunization Safety Assessment (CISA) network

Common Vaccine Myths and Facts:

Myth: Vaccines cause autism
Fact: Multiple large studies have shown no link between vaccines and autism

Myth: Natural immunity is better than vaccine immunity
Fact: Vaccines provide immunity without the risk of severe disease

Myth: Vaccines contain harmful ingredients
Fact: Ingredients are present in very small, safe amounts

Myth: Too many vaccines overwhelm the immune system
Fact: Children's immune systems handle thousands of antigens daily

Vaccine Efficacy:
- Measles vaccine: 97% effective after two doses
- Polio vaccine: Over 99% effective
- COVID-19 vaccines: 90-95% effective against severe disease

Herd Immunity:
When enough people are vaccinated, it protects those who cannot be vaccinated:
- Infants too young for vaccines
- People with weakened immune systems
- Those with medical contraindications

Vaccine Hesitancy:
Common concerns and responses:
- Side effects: Usually mild and temporary
- Religious or philosophical exemptions: Personal choice but affects community protection
- Alternative schedules: Not recommended by health authorities

Making Informed Decisions:
- Consult reliable sources (CDC, WHO, health departments)
- Talk to healthcare providers
- Consider the risks of both vaccination and disease
- Remember that vaccines save millions of lives annually

Vaccination is a personal and community health responsibility. Staying informed helps protect yourself and others.''',
      category: 'Vaccinations',
      readTime: '9 min read',
      author: 'Dr. Amanda Foster',
      publishDate: DateTime(2024, 1, 7),
      imageUrl: 'https://via.placeholder.com/400x200?text=Vaccine+Safety', // Placeholder - add actual image to assets/images/
      tags: ['vaccines', 'immunization', 'safety', 'health', 'prevention'],
    ),

    // COVID-19 Articles
    Article(
      id: '8',
      title: 'COVID-19 Prevention and Safety Measures',
      content: '''COVID-19 continues to affect communities worldwide. Understanding prevention strategies and safety measures remains important for protecting yourself and others.

Understanding COVID-19:
COVID-19 is caused by the SARS-CoV-2 virus. It spreads primarily through respiratory droplets when an infected person talks, coughs, or sneezes.

Transmission Methods:
- Person-to-person contact
- Airborne transmission in poorly ventilated spaces
- Surface contamination (less common)

Prevention Strategies:

1. Vaccination
   - Get vaccinated and stay up to date with boosters
   - Vaccines significantly reduce severe illness and death
   - Protection against variants

2. Mask Wearing
   - Wear well-fitting masks in public indoor settings
   - N95 or KN95 masks provide best protection
   - Proper mask fit is crucial

3. Physical Distancing
   - Maintain 6 feet distance in public
   - Avoid crowded indoor spaces
   - Work from home when possible

4. Hand Hygiene
   - Wash hands frequently with soap and water
   - Use hand sanitizer with at least 60% alcohol
   - Avoid touching face

5. Ventilation
   - Improve indoor air quality
   - Open windows and use air purifiers
   - Avoid poorly ventilated spaces

6. Testing and Isolation
   - Get tested if symptomatic or exposed
   - Isolate if positive or symptomatic
   - Follow local health guidelines

High-Risk Groups:
- Older adults (65+)
- People with underlying medical conditions
- Immunocompromised individuals
- Pregnant people
- Healthcare workers

Symptoms of COVID-19:
- Fever or chills
- Cough
- Shortness of breath
- Fatigue
- Muscle or body aches
- Headache
- Loss of taste or smell
- Sore throat
- Congestion or runny nose
- Nausea or vomiting
- Diarrhea

When to Seek Medical Care:
- Difficulty breathing
- Persistent chest pain
- Confusion
- Inability to wake or stay awake
- Pale, gray, or blue skin
- High fever that doesn't respond to medication

Long COVID:
Some people experience symptoms lasting weeks or months:
- Fatigue
- Brain fog
- Shortness of breath
- Chest pain
- Joint pain
- Mental health issues

Mental Health Considerations:
- Stay connected with loved ones
- Maintain routines
- Practice stress management
- Seek mental health support if needed

COVID-19 prevention requires ongoing vigilance. Stay informed through reliable sources and follow current health guidelines.''',
      category: 'COVID-19 Info',
      readTime: '8 min read',
      author: 'Dr. Robert Lee',
      publishDate: DateTime(2024, 1, 8),
      imageUrl: 'https://via.placeholder.com/400x200?text=COVID+Prevention', // Placeholder - add actual image to assets/images/
      tags: ['COVID-19', 'prevention', 'safety', 'health', 'pandemic'],
    ),
  ];

  List<Article> getArticlesByCategory(String category) {
    return _articles.where((article) => article.category == category).toList();
  }

  List<Article> searchArticles(String query) {
    final lowerQuery = query.toLowerCase();
    return _articles.where((article) =>
      article.title.toLowerCase().contains(lowerQuery) ||
      article.content.toLowerCase().contains(lowerQuery) ||
      article.tags.any((tag) => tag.toLowerCase().contains(lowerQuery))
    ).toList();
  }
}