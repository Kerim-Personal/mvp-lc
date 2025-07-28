// lib/screens/level_assessment_screen.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lingua_chat/screens/assessment_results_screen.dart';

// Data model for questions
class Question {
  final String questionText;
  final List<String> options;
  final int correctAnswerIndex;

  const Question({
    required this.questionText,
    required this.options,
    required this.correctAnswerIndex,
  });
}

class LevelAssessmentScreen extends StatefulWidget {
  const LevelAssessmentScreen({super.key});

  @override
  State<LevelAssessmentScreen> createState() => _LevelAssessmentScreenState();
}

class _LevelAssessmentScreenState extends State<LevelAssessmentScreen> with TickerProviderStateMixin {

  // --- QUESTION POOLS (EKSİKSİZ) ---

  // Beginner Level Question Pool (A1/A2)
  final List<Question> _beginnerQuestions = const [
    Question(questionText: 'They ___ from Canada.', options: ['is', 'am', 'are', 'be'], correctAnswerIndex: 2),
    Question(questionText: '___ is your favorite color?', options: ['How', 'What', 'When', 'Who'], correctAnswerIndex: 1),
    Question(questionText: 'I have ___ apple.', options: ['a', 'an', 'the', 'any'], correctAnswerIndex: 1),
    Question(questionText: 'Can you ___ the guitar?', options: ['play', 'do', 'make', 'sing'], correctAnswerIndex: 0),
    Question(questionText: 'There ___ a big tree in the garden.', options: ['is', 'are', 'have', 'has'], correctAnswerIndex: 0),
    Question(questionText: 'I ___ to the store yesterday.', options: ['go', 'goes', 'went', 'gone'], correctAnswerIndex: 2),
    Question(questionText: 'She is wearing a ___ dress.', options: ['red', 'reds', 'a red', 'an red'], correctAnswerIndex: 0),
    Question(questionText: 'My birthday is ___ June.', options: ['at', 'on', 'in', 'by'], correctAnswerIndex: 2),
    Question(questionText: 'He ___ speak French.', options: ['not', 'no', 'don\'t', 'doesn\'t'], correctAnswerIndex: 3),
    Question(questionText: 'We ___ TV every evening.', options: ['watch', 'watches', 'watching', 'watched'], correctAnswerIndex: 0),
    Question(questionText: 'What time ___ it?', options: ['is', 'are', 'do', 'does'], correctAnswerIndex: 0),
    Question(questionText: 'I have two ___.', options: ['child', 'childs', 'children', 'childrens'], correctAnswerIndex: 2),
    Question(questionText: 'He lives in London, ___ he?', options: ['is', 'isn\'t', 'does', 'doesn\'t'], correctAnswerIndex: 3),
    Question(questionText: 'I\'m taller ___ my sister.', options: ['that', 'than', 'then', 'as'], correctAnswerIndex: 1),
    Question(questionText: 'She ___ to the radio in the morning.', options: ['listens', 'listen', 'listening', 'listened'], correctAnswerIndex: 0),
    Question(questionText: '___ many people at the party?', options: ['Was there', 'Were there', 'Is there', 'Are there'], correctAnswerIndex: 1),
    Question(questionText: 'I\'m not interested ___ sports.', options: ['on', 'at', 'in', 'for'], correctAnswerIndex: 2),
    Question(questionText: 'Could you pass me the salt, ___?', options: ['please', 'thank you', 'sorry', 'excuse me'], correctAnswerIndex: 0),
    Question(questionText: 'He works ___ a waiter.', options: ['like', 'as', 'for', 'at'], correctAnswerIndex: 1),
    Question(questionText: 'Don\'t forget ___ the door.', options: ['locking', 'to lock', 'lock', 'locked'], correctAnswerIndex: 1),
    Question(questionText: 'What are you ___?', options: ['do', 'does', 'did', 'doing'], correctAnswerIndex: 3),
    Question(questionText: 'The book is ___ the table.', options: ['on', 'in', 'at', 'under'], correctAnswerIndex: 0),
    Question(questionText: 'I can\'t find my keys ___.', options: ['nowhere', 'somewhere', 'anywhere', 'everywhere'], correctAnswerIndex: 2),
    Question(questionText: 'She is the ___ girl in the class.', options: ['smart', 'smarter', 'smartest', 'more smart'], correctAnswerIndex: 2),
    Question(questionText: 'I was born ___ 1995.', options: ['in', 'on', 'at', 'since'], correctAnswerIndex: 0),
    Question(questionText: 'He has ___ money.', options: ['a lot of', 'many', 'much', 'a few'], correctAnswerIndex: 0),
    Question(questionText: 'I would like ___ water.', options: ['some', 'any', 'a', 'an'], correctAnswerIndex: 0),
    Question(questionText: 'She never ___ meat.', options: ['eat', 'eats', 'eating', 'ate'], correctAnswerIndex: 1),
    Question(questionText: 'How ___ does this cost?', options: ['many', 'much', 'often', 'long'], correctAnswerIndex: 1),
    Question(questionText: 'I ___ my homework every day.', options: ['do', 'make', 'does', 'makes'], correctAnswerIndex: 0),
    Question(questionText: 'The opposite of "hot" is ___.', options: ['cold', 'warm', 'cool', 'freezing'], correctAnswerIndex: 0),
    Question(questionText: 'A person who flies a plane is a ___.', options: ['doctor', 'pilot', 'teacher', 'driver'], correctAnswerIndex: 1),
    Question(questionText: 'Which animal says "meow"?', options: ['Dog', 'Bird', 'Cat', 'Fish'], correctAnswerIndex: 2),
    Question(questionText: 'We use our ___ to see.', options: ['ears', 'nose', 'hands', 'eyes'], correctAnswerIndex: 3),
    Question(questionText: 'The sun ___ in the east.', options: ['rise', 'rises', 'rose', 'risen'], correctAnswerIndex: 1),
    Question(questionText: 'There are seven days in a ___.', options: ['month', 'year', 'week', 'day'], correctAnswerIndex: 2),
    Question(questionText: 'I write with a ___.', options: ['pen', 'book', 'chair', 'desk'], correctAnswerIndex: 0),
    Question(questionText: 'He is ___ a blue shirt.', options: ['wear', 'wears', 'wearing', 'wore'], correctAnswerIndex: 2),
    Question(questionText: 'My father is a ___.', options: ['man', 'woman', 'boy', 'girl'], correctAnswerIndex: 0),
    Question(questionText: 'I ___ to school by bus.', options: ['come', 'go', 'walk', 'run'], correctAnswerIndex: 1),
    Question(questionText: 'The baby is ___.', options: ['cry', 'cries', 'crying', 'cried'], correctAnswerIndex: 2),
    Question(questionText: 'I can ___ very fast.', options: ['read', 'sing', 'run', 'jump'], correctAnswerIndex: 2),
    Question(questionText: 'She has long ___.', options: ['hair', 'hairs', 'a hair', 'the hair'], correctAnswerIndex: 0),
    Question(questionText: 'This is my book, and that is ___.', options: ['your', 'yours', 'you', 'you\'re'], correctAnswerIndex: 1),
    Question(questionText: 'They are playing ___ in the park.', options: ['game', 'a game', 'the game', 'games'], correctAnswerIndex: 3),
    Question(questionText: 'I ___ tired last night.', options: ['am', 'is', 'was', 'were'], correctAnswerIndex: 2),
    Question(questionText: 'He is good ___ English.', options: ['in', 'on', 'at', 'with'], correctAnswerIndex: 2),
    Question(questionText: 'I need to buy ___ bread.', options: ['a', 'an', 'some', 'any'], correctAnswerIndex: 2),
    Question(questionText: 'She is afraid ___ spiders.', options: ['from', 'with', 'of', 'about'], correctAnswerIndex: 2),
    Question(questionText: 'What ___ you do tomorrow?', options: ['are', 'do', 'will', 'did'], correctAnswerIndex: 2),
    Question(questionText: '___ you like some coffee?', options: ['Do', 'Would', 'Are', 'Can'], correctAnswerIndex: 1),
    Question(questionText: 'There isn\'t ___ sugar in my tea.', options: ['many', 'some', 'any', 'a lot'], correctAnswerIndex: 2),
    Question(questionText: 'He is ___ person I know.', options: ['the nicer', 'the most nice', 'the nicest', 'nicest'], correctAnswerIndex: 2),
    Question(questionText: 'I have to ___ my bed every morning.', options: ['do', 'make', 'clean', 'fix'], correctAnswerIndex: 1),
    Question(questionText: 'They ___ to Italy for their holiday last year.', options: ['go', 'were going', 'went', 'have gone'], correctAnswerIndex: 2),
    Question(questionText: 'How ___ brothers and sisters do you have?', options: ['much', 'many', 'a lot of', 'some'], correctAnswerIndex: 1),
    Question(questionText: 'I enjoy ___ to music.', options: ['to listen', 'listen', 'listening', 'listened'], correctAnswerIndex: 2),
    Question(questionText: 'What\'s the time? It\'s half ___ three.', options: ['to', 'past', 'after', 'before'], correctAnswerIndex: 1),
    Question(questionText: 'This is ___ expensive car.', options: ['a', 'an', 'the', '—'], correctAnswerIndex: 0),
    Question(questionText: 'The shoes are too small ___ me.', options: ['for', 'to', 'with', 'of'], correctAnswerIndex: 0),
    Question(questionText: 'I\'m sorry, I ___ understand.', options: ['not', 'don\'t', 'doesn\'t', 'am not'], correctAnswerIndex: 1),
    Question(questionText: 'He ___ his car every weekend.', options: ['wash', 'washes', 'washing', 'washed'], correctAnswerIndex: 1),
    Question(questionText: 'I don\'t have ___ free time.', options: ['many', 'much', 'a lot', 'some'], correctAnswerIndex: 1),
    Question(questionText: 'The opposite of "fast" is ___.', options: ['quick', 'slow', 'rapid', 'speedy'], correctAnswerIndex: 1),
    Question(questionText: 'The season after summer is ___.', options: ['spring', 'winter', 'autumn', 'fall'], correctAnswerIndex: 2),
    Question(questionText: 'We eat breakfast in the ___.', options: ['evening', 'afternoon', 'morning', 'night'], correctAnswerIndex: 2),
    Question(questionText: 'A cat has four ___.', options: ['hands', 'feet', 'legs', 'arms'], correctAnswerIndex: 2),
    Question(questionText: 'He ___ a letter to his friend.', options: ['writes', 'write', 'writing', 'is writing'], correctAnswerIndex: 3),
    Question(questionText: 'The ___ is very cold today.', options: ['water', 'weather', 'wear', 'wind'], correctAnswerIndex: 1),
    Question(questionText: 'Look! The dog ___.', options: ['run', 'runs', 'is running', 'ran'], correctAnswerIndex: 2),
    Question(questionText: 'I like ___ apples.', options: ['eat', 'to eat', 'eating', 'ate'], correctAnswerIndex: 2),
    Question(questionText: 'This flower is beautiful, but that one is ___ beautiful.', options: ['more', 'most', 'very', 'much'], correctAnswerIndex: 0),
    Question(questionText: 'I can speak English, ___ I can\'t speak German.', options: ['and', 'so', 'but', 'or'], correctAnswerIndex: 2),
    Question(questionText: 'She is ___ a taxi.', options: ['wait for', 'waits for', 'waiting for', 'waited for'], correctAnswerIndex: 2),
    Question(questionText: 'I didn\'t ___ TV last night.', options: ['watch', 'watched', 'watching', 'watches'], correctAnswerIndex: 0),
    Question(questionText: 'I have to go to the dentist because I have a ___.', options: ['headache', 'stomachache', 'toothache', 'backache'], correctAnswerIndex: 2),
    Question(questionText: '___ you ever been to Paris?', options: ['Do', 'Did', 'Have', 'Are'], correctAnswerIndex: 2),
    Question(questionText: 'My pencils are in my ___ case.', options: ['pen', 'pencil', 'school', 'bag'], correctAnswerIndex: 1),
    Question(questionText: 'The fish can ___.', options: ['fly', 'swim', 'run', 'climb'], correctAnswerIndex: 1),
    Question(questionText: 'A ___ has a long neck.', options: ['lion', 'monkey', 'elephant', 'giraffe'], correctAnswerIndex: 3),
    Question(questionText: 'We ___ to the cinema last Friday.', options: ['go', 'are going', 'went', 'have gone'], correctAnswerIndex: 2),
    Question(questionText: 'She is from ___. She is French.', options: ['Spain', 'Germany', 'France', 'Italy'], correctAnswerIndex: 2),
    Question(questionText: 'He usually ___ coffee in the morning.', options: ['drink', 'drinks', 'is drinking', 'drank'], correctAnswerIndex: 1),
    Question(questionText: 'How ___ do you go to the gym?', options: ['many', 'much', 'long', 'often'], correctAnswerIndex: 3),
    Question(questionText: 'I am not as tall ___ my father.', options: ['so', 'as', 'than', 'that'], correctAnswerIndex: 1),
    Question(questionText: 'Can I have ___ water, please?', options: ['a glass of', 'a cup of', 'a bottle of', 'a piece of'], correctAnswerIndex: 0),
    Question(questionText: 'She is married ___ a dentist.', options: ['with', 'to', 'on', 'by'], correctAnswerIndex: 1),
    Question(questionText: 'I\'m sorry for ___ late.', options: ['be', 'to be', 'being', 'been'], correctAnswerIndex: 2),
    Question(questionText: 'He is interested ___ history.', options: ['in', 'on', 'at', 'about'], correctAnswerIndex: 0),
    Question(questionText: 'I am looking for my keys. I can\'t find ___ anywhere.', options: ['it', 'them', 'this', 'that'], correctAnswerIndex: 1),
    Question(questionText: 'The opposite of "expensive" is ___.', options: ['cheap', 'dear', 'pricey', 'costly'], correctAnswerIndex: 0),
    Question(questionText: 'I was very tired, ___ I went to bed early.', options: ['but', 'and', 'so', 'because'], correctAnswerIndex: 2),
    Question(questionText: 'She gave me a beautiful ___ for my birthday.', options: ['present', 'presence', 'pleasant', 'peasant'], correctAnswerIndex: 0),
    Question(questionText: 'He has lived in New York ___ 2010.', options: ['for', 'since', 'in', 'at'], correctAnswerIndex: 1),
    Question(questionText: 'We need to buy some ___ at the supermarket.', options: ['groceries', 'gross', 'growth', 'grace'], correctAnswerIndex: 0),
    Question(questionText: 'The train arrives ___ platform 5.', options: ['in', 'on', 'at', 'to'], correctAnswerIndex: 2),
  ];

  // Intermediate Level Question Pool (B1/B2)
  final List<Question> _intermediateQuestions = const [
    Question(questionText: 'He has been working here ___ ten years.', options: ['since', 'for', 'ago', 'in'], correctAnswerIndex: 1),
    Question(questionText: 'If I had known, I ___ have helped you.', options: ['would', 'will', 'should', 'could'], correctAnswerIndex: 0),
    Question(questionText: 'The book, ___ I read last week, was amazing.', options: ['that', 'who', 'which', 'whose'], correctAnswerIndex: 2),
    Question(questionText: 'He is responsible ___ the marketing department.', options: ['of', 'with', 'for', 'about'], correctAnswerIndex: 2),
    Question(questionText: 'I\'m not used to ___ so early.', options: ['get up', 'getting up', 'got up', 'have gotten up'], correctAnswerIndex: 1),
    Question(questionText: 'She insisted ___ paying for the meal.', options: ['on', 'to', 'in', 'with'], correctAnswerIndex: 0),
    Question(questionText: 'By the time the police arrived, the thief ___.', options: ['disappeared', 'has disappeared', 'had disappeared', 'was disappearing'], correctAnswerIndex: 2),
    Question(questionText: 'I would rather you ___ make so much noise.', options: ['don\'t', 'didn\'t', 'not', 'wouldn\'t'], correctAnswerIndex: 1),
    Question(questionText: 'It is a good idea to ___ a new hobby.', options: ['take on', 'take in', 'take up', 'take over'], correctAnswerIndex: 2),
    Question(questionText: 'He was accused ___ stealing the money.', options: ['for', 'of', 'with', 'on'], correctAnswerIndex: 1),
    Question(questionText: 'I wish I ___ more time to travel.', options: ['have', 'had', 'will have', 'would have'], correctAnswerIndex: 1),
    Question(questionText: 'The problem was more complicated ___ we thought.', options: ['that', 'than', 'as', 'then'], correctAnswerIndex: 1),
    Question(questionText: 'She has a talent ___ learning languages.', options: ['for', 'in', 'on', 'with'], correctAnswerIndex: 0),
    Question(questionText: 'He managed ___ the project on time.', options: ['to complete', 'completing', 'complete', 'completed'], correctAnswerIndex: 0),
    Question(questionText: 'I\'m looking forward ___ from you.', options: ['to hear', 'hearing', 'to hearing', 'heard'], correctAnswerIndex: 2),
    Question(questionText: 'The film is based ___ a true story.', options: ['on', 'in', 'at', 'from'], correctAnswerIndex: 0),
    Question(questionText: 'You ___ have seen him, he is on holiday.', options: ['must', 'should', 'can\'t', 'might'], correctAnswerIndex: 2),
    Question(questionText: 'Despite ___ hard, he failed the exam.', options: ['studying', 'to study', 'study', 'he studied'], correctAnswerIndex: 0),
    Question(questionText: 'The government plans to ___ taxes.', options: ['rise', 'raise', 'arise', 'arouse'], correctAnswerIndex: 1),
    Question(questionText: 'I am fed up ___ this weather.', options: ['of', 'with', 'about', 'from'], correctAnswerIndex: 1),
    Question(questionText: 'She has a great ___ of humor.', options: ['sense', 'feeling', 'touch', 'taste'], correctAnswerIndex: 0),
    Question(questionText: 'The company decided to ___ its operations.', options: ['expand', 'expend', 'extend', 'expose'], correctAnswerIndex: 0),
    Question(questionText: 'He is known for his ___ and generosity.', options: ['humble', 'humbly', 'humility', 'humiliate'], correctAnswerIndex: 2),
    Question(questionText: 'The new law will come into ___ next month.', options: ['force', 'action', 'play', 'effect'], correctAnswerIndex: 3),
    Question(questionText: 'I can\'t ___ with this noise any longer.', options: ['put up', 'put on', 'put in', 'put off'], correctAnswerIndex: 0),
    Question(questionText: 'She takes ___ her mother.', options: ['after', 'in', 'on', 'up'], correctAnswerIndex: 0),
    Question(questionText: 'The concert was a complete ___.', options: ['sell-out', 'sell-in', 'sell-on', 'sell-off'], correctAnswerIndex: 0),
    Question(questionText: 'He is a very ___ person.', options: ['rely', 'reliable', 'reliability', 'reliant'], correctAnswerIndex: 1),
    Question(questionText: 'I am ___ of spiders.', options: ['terrify', 'terrifying', 'terrified', 'terrific'], correctAnswerIndex: 2),
    Question(questionText: 'The police are looking ___ the case.', options: ['into', 'onto', 'up to', 'out of'], correctAnswerIndex: 0),
    Question(questionText: 'She is very good ___ painting.', options: ['in', 'on', 'at', 'with'], correctAnswerIndex: 2),
    Question(questionText: 'I am not ___ with the service.', options: ['satisfy', 'satisfying', 'satisfied', 'satisfaction'], correctAnswerIndex: 2),
    Question(questionText: 'He is ___ to win the competition.', options: ['like', 'likely', 'alike', 'likeness'], correctAnswerIndex: 1),
    Question(questionText: 'The ___ of the rainforest is a major concern.', options: ['destroy', 'destruction', 'destructive', 'destroyed'], correctAnswerIndex: 1),
    Question(questionText: 'She is a very ___ and ambitious woman.', options: ['determine', 'determined', 'determination', 'determining'], correctAnswerIndex: 1),
    Question(questionText: 'The company made a huge ___ last year.', options: ['profit', 'benefit', 'gain', 'advantage'], correctAnswerIndex: 0),
    Question(questionText: 'He is an ___ in his field.', options: ['export', 'expert', 'excerpt', 'exempt'], correctAnswerIndex: 1),
    Question(questionText: 'The government is trying to ___ the economy.', options: ['boost', 'boast', 'boastful', 'booster'], correctAnswerIndex: 0),
    Question(questionText: 'She is a very ___ person.', options: ['create', 'creative', 'creation', 'creator'], correctAnswerIndex: 1),
    Question(questionText: 'The ___ of the project was a success.', options: ['come out', 'outcome', 'income', 'coming'], correctAnswerIndex: 1),
    Question(questionText: 'He is a very ___ and honest person.', options: ['depend', 'dependable', 'dependence', 'dependent'], correctAnswerIndex: 1),
    Question(questionText: 'The company is facing a lot of ___ from its rivals.', options: ['compete', 'competitive', 'competition', 'competitor'], correctAnswerIndex: 2),
    Question(questionText: 'She is a very ___ and talented musician.', options: ['gift', 'gifted', 'gifting', 'gifts'], correctAnswerIndex: 1),
    Question(questionText: 'The ___ of the new product was a great success.', options: ['launch', 'lunch', 'lunge', 'lurch'], correctAnswerIndex: 0),
    Question(questionText: 'He is a very ___ and influential person.', options: ['power', 'powerful', 'powerless', 'powerfully'], correctAnswerIndex: 1),
    Question(questionText: 'The company has a very ___ brand image.', options: ['strong', 'strength', 'strengthen', 'strongly'], correctAnswerIndex: 0),
    Question(questionText: 'She is a very ___ and dedicated teacher.', options: ['passion', 'passionate', 'passionless', 'passionately'], correctAnswerIndex: 1),
    Question(questionText: 'The ___ of the company is to provide high-quality products.', options: ['mission', 'mishap', 'missing', 'missive'], correctAnswerIndex: 0),
    Question(questionText: 'He is a very ___ and experienced lawyer.', options: ['skill', 'skilled', 'skillful', 'skilling'], correctAnswerIndex: 1),
    Question(questionText: 'The company has a very ___ and loyal customer base.', options: ['faith', 'faithful', 'faithless', 'faithfully'], correctAnswerIndex: 1),
    Question(questionText: 'The news ___ better than expected.', options: ['was', 'were', 'is', 'are'], correctAnswerIndex: 0),
    Question(questionText: 'Neither of the students ___ the answer.', options: ['know', 'knows', 'knowing', 'have known'], correctAnswerIndex: 1),
    Question(questionText: 'This time tomorrow, I ___ on a beach.', options: ['will lie', 'will be lying', 'lie', 'am lying'], correctAnswerIndex: 1),
    Question(questionText: 'The car needs ___.', options: ['to fix', 'fixing', 'fixed', 'fix'], correctAnswerIndex: 1),
    Question(questionText: 'He denied ___ the window.', options: ['to break', 'breaking', 'break', 'broke'], correctAnswerIndex: 1),
    Question(questionText: 'I\'m having my car ___ this afternoon.', options: ['repair', 'to repair', 'repairing', 'repaired'], correctAnswerIndex: 3),
    Question(questionText: 'It\'s about time you ___ apologizing.', options: ['stop', 'stopped', 'to stop', 'stopping'], correctAnswerIndex: 1),
    Question(questionText: 'He regrets ___ his job.', options: ['to leave', 'leaving', 'leave', 'left'], correctAnswerIndex: 1),
    Question(questionText: 'On no account ___ you touch that button.', options: ['should', 'shouldn\'t', 'must', 'mustn\'t'], correctAnswerIndex: 0),
    Question(questionText: 'Hardly ___ I arrived when the trouble started.', options: ['had', 'have', 'did', 'was'], correctAnswerIndex: 0),
    Question(questionText: 'This is a matter of ___ concern.', options: ['grave', 'gravely', 'gravity', 'grief'], correctAnswerIndex: 0),
    Question(questionText: 'She has a ___ for languages.', options: ['skill', 'aptitude', 'talent', 'ability'], correctAnswerIndex: 1),
    Question(questionText: 'The company has to ___ with the new regulations.', options: ['comply', 'apply', 'reply', 'imply'], correctAnswerIndex: 0),
    Question(questionText: 'He was ___ for his bravery.', options: ['praised', 'priced', 'prized', 'prised'], correctAnswerIndex: 0),
    Question(questionText: 'The ___ of the new building took two years.', options: ['construct', 'construction', 'constructive', 'constructed'], correctAnswerIndex: 1),
    Question(questionText: 'She is a very ___ and efficient worker.', options: ['method', 'methodical', 'methodology', 'methodist'], correctAnswerIndex: 1),
    Question(questionText: 'The government has implemented ___ measures to control inflation.', options: ['drastic', 'dramatic', 'draconian', 'durable'], correctAnswerIndex: 0),
    Question(questionText: 'The painting is a ___ of a young woman.', options: ['portrait', 'portray', 'portrayal', 'portent'], correctAnswerIndex: 0),
    Question(questionText: 'He has a very ___ sense of humor.', options: ['dry', 'wet', 'damp', 'moist'], correctAnswerIndex: 0),
    Question(questionText: 'The ___ of the two rivers is a beautiful sight.', options: ['confluence', 'conflict', 'conformity', 'confusion'], correctAnswerIndex: 0),
    Question(questionText: 'She is a very ___ and persuasive speaker.', options: ['convince', 'convincing', 'convinced', 'conviction'], correctAnswerIndex: 1),
    Question(questionText: 'The company is committed to ___ development.', options: ['sustain', 'sustainable', 'sustainability', 'sustenance'], correctAnswerIndex: 1),
    Question(questionText: 'He is a ___ opponent of the new law.', options: ['staunch', 'stain', 'stalk', 'stall'], correctAnswerIndex: 0),
    Question(questionText: 'The ___ of the evidence points to his guilt.', options: ['weight', 'weigh', 'weighing', 'weighed'], correctAnswerIndex: 0),
    Question(questionText: 'She is a very ___ and versatile actress.', options: ['acclaim', 'acclaimed', 'acclamation', 'acclimate'], correctAnswerIndex: 1),
    Question(questionText: 'The ___ of the city is its rich history.', options: ['allure', 'allude', 'allusion', 'ally'], correctAnswerIndex: 0),
    Question(questionText: 'He is a ___ supporter of the local team.', options: ['fervent', 'fervid', 'fervor', 'ferment'], correctAnswerIndex: 0),
    Question(questionText: 'The ___ of the novel is its complex plot.', options: ['strength', 'strong', 'strengthen', 'strongly'], correctAnswerIndex: 0),
    Question(questionText: 'She has a ___ for telling stories.', options: ['flair', 'flare', 'flay', 'flak'], correctAnswerIndex: 0),
    Question(questionText: 'The ___ of the two cultures is fascinating.', options: ['juxtaposition', 'justification', 'juncture', 'jurisdiction'], correctAnswerIndex: 0),
    Question(questionText: 'He is a ___ of traditional values.', options: ['proponent', 'propensity', 'proposal', 'proposition'], correctAnswerIndex: 0),
    Question(questionText: 'The ___ of the project is to improve public transport.', options: ['scope', 'scape', 'scalp', 'scamp'], correctAnswerIndex: 0),
    Question(questionText: 'She is a ___ and respected journalist.', options: ['veteran', 'veterinarian', 'veto', 'vex'], correctAnswerIndex: 0),
    Question(questionText: 'The ___ of the company is its commitment to quality.', options: ['ethos', 'ether', 'ethic', 'ethnic'], correctAnswerIndex: 0),
    Question(questionText: 'He is a ___ critic of the government.', options: ['vociferous', 'voracious', 'veracious', 'volatile'], correctAnswerIndex: 0),
    Question(questionText: 'The ___ of the problem is a lack of resources.', options: ['core', 'corps', 'corpse', 'corpus'], correctAnswerIndex: 0),
    Question(questionText: 'She has a ___ knowledge of the subject.', options: ['profound', 'profuse', 'profane', 'profile'], correctAnswerIndex: 0),
    Question(questionText: 'The ___ of the meeting is to discuss the new budget.', options: ['agenda', 'agent', 'agency', 'agile'], correctAnswerIndex: 0),
    Question(questionText: 'He is a ___ and successful entrepreneur.', options: ['dynamic', 'dynamite', 'dynasty', 'dynamo'], correctAnswerIndex: 0),
    Question(questionText: 'The ___ of the city is its vibrant nightlife.', options: ['hallmark', 'halfway', 'hallowed', 'haphazard'], correctAnswerIndex: 0),
    Question(questionText: 'She is a ___ and influential figure in the fashion industry.', options: ['prominent', 'prompt', 'prone', 'prong'], correctAnswerIndex: 0),
    Question(questionText: 'The ___ of the company is its commitment to quality.', options: ['cornerstone', 'corner', 'cornet', 'cornea'], correctAnswerIndex: 0),
  ];

  // Advanced Level Question Pool (C1/C2)
  final List<Question> _advancedQuestions = const [
    Question(questionText: 'The new regulations will be ___ next month.', options: ['implemented', 'implicated', 'implored', 'imparted'], correctAnswerIndex: 0),
    Question(questionText: 'The artist\'s work is a ___ of different styles.', options: ['fusion', 'fission', 'fixation', 'fabrication'], correctAnswerIndex: 0),
    Question(questionText: 'He was known for his ___ wit and sharp tongue.', options: ['acerbic', 'amiable', 'ambiguous', 'apathetic'], correctAnswerIndex: 0),
    Question(questionText: 'The ___ of the problem lies in the lack of funding.', options: ['crux', 'crest', 'crypt', 'craft'], correctAnswerIndex: 0),
    Question(questionText: 'She has a(n) ___ for detail.', options: ['eye', 'ear', 'nose', 'hand'], correctAnswerIndex: 0),
    Question(questionText: 'The company is trying to ___ its market share.', options: ['consolidate', 'console', 'conspire', 'constrain'], correctAnswerIndex: 0),
    Question(questionText: 'He is a ___ of the arts.', options: ['patron', 'patriot', 'pioneer', 'pedant'], correctAnswerIndex: 0),
    Question(questionText: 'The ___ of the two companies created a new industry giant.', options: ['merger', 'miser', 'mentor', 'matrix'], correctAnswerIndex: 0),
    Question(questionText: 'She is a ___ reader of classic literature.', options: ['voracious', 'veracious', 'verbose', 'volatile'], correctAnswerIndex: 0),
    Question(questionText: 'The government\'s ___ has been widely criticized.', options: ['policy', 'police', 'polish', 'polity'], correctAnswerIndex: 0),
    Question(questionText: 'He has a ___ for making people laugh.', options: ['knack', 'snack', 'stack', 'track'], correctAnswerIndex: 0),
    Question(questionText: 'The ___ of the situation is that we have no other choice.', options: ['irony', 'icon', 'idea', 'idyll'], correctAnswerIndex: 0),
    Question(questionText: 'She is a very ___ and articulate speaker.', options: ['eloquent', 'elegant', 'elusive', 'emetic'], correctAnswerIndex: 0),
    Question(questionText: 'The ___ of the new law is to reduce crime.', options: ['purpose', 'porpoise', 'portent', 'portal'], correctAnswerIndex: 0),
    Question(questionText: 'He is a very ___ and resourceful person.', options: ['ingenious', 'ingenuous', 'ingrained', 'ingrate'], correctAnswerIndex: 0),
    Question(questionText: 'The ___ of the evidence is overwhelming.', options: ['preponderance', 'preposition', 'prepossession', 'premonition'], correctAnswerIndex: 0),
    Question(questionText: 'She is a very ___ and determined person.', options: ['resilient', 'resonant', 'resolute', 'restive'], correctAnswerIndex: 2),
    Question(questionText: 'The ___ of the company is to be the market leader.', options: ['vision', 'visit', 'vista', 'visor'], correctAnswerIndex: 0),
    Question(questionText: 'He is a very ___ and respected member of the community.', options: ['venerable', 'vulnerable', 'venal', 'venial'], correctAnswerIndex: 0),
    Question(questionText: 'The ___ of the problem is its complexity.', options: ['gist', 'jest', 'jist', 'just'], correctAnswerIndex: 0),
    Question(questionText: 'She has a very ___ sense of style.', options: ['eclectic', 'electric', 'ecliptic', 'ecstatic'], correctAnswerIndex: 0),
    Question(questionText: 'The ___ of the novel is set in the 19th century.', options: ['milieu', 'miel', 'mewl', 'mien'], correctAnswerIndex: 0),
    Question(questionText: 'He is a very ___ and astute businessman.', options: ['shrewd', 'shrew', 'shroud', 'shriek'], correctAnswerIndex: 0),
    Question(questionText: 'The ___ of the argument is that we need to act now.', options: ['tenor', 'tenet', 'tenon', 'tenure'], correctAnswerIndex: 1),
    Question(questionText: 'She is a very ___ and compassionate person.', options: ['empathetic', 'emetic', 'emphatic', 'empirical'], correctAnswerIndex: 0),
    Question(questionText: 'The ___ of his argument was that the plan was flawed.', options: ['thrust', 'thrush', 'thrum', 'thud'], correctAnswerIndex: 0),
    Question(questionText: 'He is a very ___ and meticulous researcher.', options: ['scrupulous', 'scurrilous', 'scurvy', 'scummy'], correctAnswerIndex: 0),
    Question(questionText: 'The ___ of the matter is that we are running out of time.', options: ['nub', 'nab', 'nib', 'nob'], correctAnswerIndex: 0),
    Question(questionText: 'She is a very ___ and insightful critic.', options: ['perspicacious', 'perspicuous', 'perspiring', 'persuading'], correctAnswerIndex: 0),
    Question(questionText: 'The ___ of the problem is the lack of communication.', options: ['kernel', 'kennel', 'ken', 'kestrel'], correctAnswerIndex: 0),
    Question(questionText: 'He is a very ___ and eloquent speaker.', options: ['articulate', 'artful', 'artificial', 'artisan'], correctAnswerIndex: 0),
    Question(questionText: 'The ___ of the issue is the allocation of resources.', options: ['crux', 'crutch', 'crude', 'cruet'], correctAnswerIndex: 0),
    Question(questionText: 'She is a very ___ and discerning collector.', options: ['astute', 'acute', 'abstruse', 'absurd'], correctAnswerIndex: 0),
    Question(questionText: 'The ___ of his speech was the need for unity.', options: ['leitmotif', 'leitmotiv', 'leit-motiv', 'leit-motif'], correctAnswerIndex: 0),
    Question(questionText: 'He is a very ___ and erudite scholar.', options: ['learned', 'learning', 'learn', 'learns'], correctAnswerIndex: 0),
    Question(questionText: 'The ___ of the play is the theme of betrayal.', options: ['subtext', 'subject', 'subjoin', 'sublate'], correctAnswerIndex: 0),
    Question(questionText: 'She is a very ___ and perceptive observer.', options: ['keen', 'ken', 'keep', 'kempt'], correctAnswerIndex: 0),
    Question(questionText: 'The ___ of the problem is the lack of a clear strategy.', options: ['pith', 'pity', 'pithy', 'piton'], correctAnswerIndex: 0),
    Question(questionText: 'He is a very ___ and insightful analyst.', options: ['trenchant', 'trench', 'trencher', 'trencherman'], correctAnswerIndex: 0),
    Question(questionText: 'The ___ of the argument is the need for immediate action.', options: ['gravamen', 'gravel', 'graven', 'graver'], correctAnswerIndex: 0),
    Question(questionText: 'She is a very ___ and incisive commentator.', options: ['cogent', 'co-gent', 'co-agent', 'coagent'], correctAnswerIndex: 0),
    Question(questionText: 'The ___ of the matter is that we cannot afford to fail.', options: ['long and short of it', 'long and the short of it', 'long and short', 'long of it'], correctAnswerIndex: 1),
    Question(questionText: 'He is a very ___ and compelling storyteller.', options: ['raconteur', 'racketeer', 'racket', 'racoon'], correctAnswerIndex: 0),
    Question(questionText: 'The ___ of the problem is the lack of political will.', options: ['nub of the matter', 'nub of the problem', 'nub of it', 'nub'], correctAnswerIndex: 1),
    Question(questionText: 'She is a very ___ and witty conversationalist.', options: ['sparkling', 'sparkle', 'spark', 'sparky'], correctAnswerIndex: 0),
    Question(questionText: 'The ___ of the argument is that we need to be more proactive.', options: ['bottom line', 'bottom-line', 'bottom', 'line'], correctAnswerIndex: 0),
    Question(questionText: 'He is a very ___ and engaging speaker.', options: ['charismatic', 'characteristic', 'character', 'characterful'], correctAnswerIndex: 0),
    Question(questionText: 'The ___ of the issue is the need for a long-term solution.', options: ['heart of the matter', 'heart of the problem', 'heart of it', 'heart'], correctAnswerIndex: 0),
    Question(questionText: 'She is a very ___ and polished performer.', options: ['consummate', 'consummation', 'consume', 'consumer'], correctAnswerIndex: 0),
    Question(questionText: 'The ___ of the problem is the lack of a coherent policy.', options: ['root of the matter', 'root of the problem', 'root of it', 'root'], correctAnswerIndex: 1),
    Question(questionText: 'No sooner ___ the room than the fire alarm went off.', options: ['had he entered', 'he had entered', 'did he enter', 'he entered'], correctAnswerIndex: 0),
    Question(questionText: 'The company\'s ___ were not as high as expected.', options: ['earnings', 'earn', 'earned', 'earner'], correctAnswerIndex: 0),
    Question(questionText: 'She has an ___ talent for music.', options: ['innate', 'insane', 'inane', 'inert'], correctAnswerIndex: 0),
    Question(questionText: 'The decision was made by ___ consensus.', options: ['unanimous', 'uniform', 'united', 'universal'], correctAnswerIndex: 0),
    Question(questionText: 'The lawyer tried to ___ the jury\'s decision.', options: ['influence', 'infect', 'inflict', 'infringe'], correctAnswerIndex: 0),
    Question(questionText: 'His speech was so ___ that many people were moved to tears.', options: ['poignant', 'pungent', 'potent', 'paltry'], correctAnswerIndex: 0),
    Question(questionText: 'The government is facing a ___ of criticism.', options: ['barrage', 'barricade', 'barometer', 'barrister'], correctAnswerIndex: 0),
    Question(questionText: 'She is a ___ supporter of animal rights.', options: ['staunch', 'stark', 'startled', 'static'], correctAnswerIndex: 0),
    Question(questionText: 'The ___ of the problem is a lack of trust.', options: ['linchpin', 'lynchpin', 'lagniappe', 'lampoon'], correctAnswerIndex: 0),
    Question(questionText: 'He has a ___ for getting into trouble.', options: ['propensity', 'property', 'proposal', 'propriety'], correctAnswerIndex: 0),
    Question(questionText: 'The ___ of the evidence is indisputable.', options: ['veracity', 'voracity', 'velocity', 'verbosity'], correctAnswerIndex: 0),
    Question(questionText: 'She is known for her ___ and attention to detail.', options: ['meticulousness', 'malice', 'magnanimity', 'malevolence'], correctAnswerIndex: 0),
    Question(questionText: 'The ___ of the new policy is still a matter of debate.', options: ['efficacy', 'effigy', 'effluence', 'effrontery'], correctAnswerIndex: 0),
    Question(questionText: 'He has a ___ knowledge of ancient history.', options: ['encyclopedic', 'endemic', 'endearing', 'endogenous'], correctAnswerIndex: 0),
    Question(questionText: 'The ___ of his argument was that the system is broken.', options: ['thesis', 'theme', 'theory', 'thesaurus'], correctAnswerIndex: 0),
    Question(questionText: 'She has a very ___ and analytical mind.', options: ['incisive', 'indecisive', 'inclusive', 'inconclusive'], correctAnswerIndex: 0),
    Question(questionText: 'The ___ of the crisis is yet to be seen.', options: ['aftermath', 'afterthought', 'afterlife', 'aftershock'], correctAnswerIndex: 0),
    Question(questionText: 'He is a ___ and respected statesman.', options: ['distinguished', 'distinct', 'distorted', 'distraught'], correctAnswerIndex: 0),
    Question(questionText: 'The ___ of the problem is its multifaceted nature.', options: ['complexity', 'complexion', 'compliance', 'complicity'], correctAnswerIndex: 0),
    Question(questionText: 'She is a very ___ and generous benefactor.', options: ['munificent', 'malignant', 'magnificent', 'malevolent'], correctAnswerIndex: 0),
    Question(questionText: 'The ___ of the evidence is compelling.', options: ['cogency', 'co-agency', 'co-agent', 'co-gency'], correctAnswerIndex: 0),
    Question(questionText: 'He is a ___ of the old school.', options: ['scion', 'scion', 'scion', 'scion'], correctAnswerIndex: 0),
    Question(questionText: 'The ___ of the situation is that there are no easy answers.', options: ['quandary', 'quarry', 'quaver', 'quay'], correctAnswerIndex: 0),
    Question(questionText: 'She has a ___ for making friends easily.', options: ['penchant', 'pendant', 'pennant', 'penalty'], correctAnswerIndex: 0),
    Question(questionText: 'The ___ of the two styles is a unique blend.', options: ['amalgamation', 'ambush', 'amenity', 'amulet'], correctAnswerIndex: 0),
    Question(questionText: 'He is a ___ and influential lobbyist.', options: ['powerful', 'powerless', 'powerfully', 'power'], correctAnswerIndex: 0),
    Question(questionText: 'The ___ of the company is its innovative culture.', options: ['hallmark', 'halfway', 'hallowed', 'haphazard'], correctAnswerIndex: 0),
    Question(questionText: 'She is a ___ and respected academic.', options: ['luminary', 'lumber', 'lump', 'lunar'], correctAnswerIndex: 0),
    Question(questionText: 'The ___ of the problem is the lack of a clear vision.', options: ['core', 'corps', 'corpse', 'corpus'], correctAnswerIndex: 0),
    Question(questionText: 'He has a ___ and encyclopedic knowledge of the subject.', options: ['vast', 'fast', 'past', 'last'], correctAnswerIndex: 0),
    Question(questionText: 'The ___ of the argument is that we need a new approach.', options: ['upshot', 'uproar', 'upside', 'upstart'], correctAnswerIndex: 0),
    Question(questionText: 'She is a very ___ and sophisticated woman.', options: ['urbane', 'urban', 'urchin', 'urgent'], correctAnswerIndex: 0),
    Question(questionText: 'The ___ of the matter is that we are out of options.', options: ['reality', 'real', 'realism', 'realist'], correctAnswerIndex: 0),
    Question(questionText: 'He is a ___ and respected leader.', options: ['charismatic', 'characteristic', 'character', 'characterful'], correctAnswerIndex: 0),
    Question(questionText: 'The ___ of the problem is the lack of a sustainable solution.', options: ['essence', 'essential', 'esteem', 'estimate'], correctAnswerIndex: 0),
    Question(questionText: 'She is a very ___ and inspiring mentor.', options: ['dynamic', 'dynamite', 'dynasty', 'dynamo'], correctAnswerIndex: 0),
    Question(questionText: 'The ___ of the company is its strong ethical code.', options: ['bedrock', 'bedroll', 'bedroom', 'bedside'], correctAnswerIndex: 0),
  ];

  late List<Question> _selectedQuestions;
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _isLoading = false;
  bool _isTestStarted = false;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  void _prepareTest() {
    final random = Random();

    // Tüm soruları tek bir listede birleştirelim
    final List<Question> allQuestions = [
      ..._beginnerQuestions,
      ..._intermediateQuestions,
      ..._advancedQuestions,
    ];

    allQuestions.shuffle(random);

    // Test için 20 soru seçelim
    _selectedQuestions = allQuestions.take(20).toList();

    if (mounted) {
      setState(() {
        _isTestStarted = true;
        _animationController.forward(from: 0.0);
      });
    }
  }

  void _answerQuestion(int selectedOptionIndex) {
    if (selectedOptionIndex == _selectedQuestions[_currentQuestionIndex].correctAnswerIndex) {
      _score++;
    }

    if (_currentQuestionIndex < _selectedQuestions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _animationController.forward(from: 0.0);
      });
    } else {
      _finishQuiz();
    }
  }

  String _calculateLevel(int score) {
    double correctRatio = score / _selectedQuestions.length;
    if (correctRatio <= 0.33) return 'A1';
    if (correctRatio <= 0.5) return 'A2';
    if (correctRatio <= 0.7) return 'B1';
    if (correctRatio <= 0.85) return 'B2';
    if (correctRatio <= 0.95) return 'C1';
    return 'C2';
  }

  Future<void> _finishQuiz() async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final level = _calculateLevel(_score);
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'level': level});
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => AssessmentResultsScreen(
              score: _score,
              totalQuestions: _selectedQuestions.length,
              level: level,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Seviye kaydedilemedi: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Seviye Belirleme Testi'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        centerTitle: true,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: _isTestStarted ? _buildQuestionView() : _buildWelcomeView(),
      ),
    );
  }

  Widget _buildWelcomeView() {
    return Container(
      key: const ValueKey('welcome'),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.school_outlined, size: 120, color: Colors.teal.shade300),
          const SizedBox(height: 24),
          const Text(
            'Dil Seviyeni Keşfet!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'Sana en uygun pratik partnerlerini bulabilmemiz için kısa bir testle İngilizce seviyeni belirleyelim.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600, height: 1.5),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _prepareTest,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              elevation: 5,
              shadowColor: Colors.teal.withOpacity(0.5),
            ),
            child: const Text('Teste Başla', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionView() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final currentQuestion = _selectedQuestions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / _selectedQuestions.length;

    return Container(
      key: const ValueKey('questions'),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: SizedBox(
              width: 80,
              height: 80,
              child: TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: progress),
                duration: const Duration(milliseconds: 500),
                builder: (context, value, child) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: value,
                        strokeWidth: 8,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
                      ),
                      Center(
                        child: Text(
                          '${_currentQuestionIndex + 1}/${_selectedQuestions.length}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: FadeTransition(
                  opacity: _animationController,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(_animationController),
                    child: Text(
                      currentQuestion.questionText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, height: 1.4),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          ...List.generate(currentQuestion.options.length, (index) {
            return FadeTransition(
              opacity: _animationController,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
                    CurvedAnimation(parent: _animationController, curve: Interval(0.2 * index, 1.0, curve: Curves.easeOut))),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: Colors.teal,
                      side: const BorderSide(color: Colors.teal, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    onPressed: () => _answerQuestion(index),
                    child: Text(currentQuestion.options[index]),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}