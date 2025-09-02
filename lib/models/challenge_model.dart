// lib/models/challenge_model.dart

class Challenge {
  final String title;
  final String description;
  final List<String> exampleSentences;

  const Challenge({
    required this.title,
    required this.description,
    required this.exampleSentences,
  });
}

// A list of 30 different challenges with titles and example sentences
const List<Challenge> challenges = [
  Challenge(
    title: "Describe Your Favorite Movie",
    description: "Tell your partner about your favorite movie today and why you love it.",
    exampleSentences: [
      "Have you ever seen the movie '[Movie Title]'? It's my favorite.",
      "I really love '[Movie Title]' because the story is amazing.",
      "If you like [Genre] movies, you should definitely watch '[Movie Title]'.",
    ],
  ),
  Challenge(
    title: "Use 5 New Words",
    description: "Try to use 5 new English words in your conversation today that you haven't used before.",
    exampleSentences: [
      "I learned a new word today, it's 'serendipity'.",
      "Let me try to use this word in a sentence...",
      "Could you tell me if I'm using the word 'ubiquitous' correctly?",
    ],
  ),
  Challenge(
    title: "Describe Your Dream Vacation",
    description: "Close your eyes and describe that perfect vacation you want to go on to your partner.",
    exampleSentences: [
      "My dream vacation would be a trip to Japan.",
      "I would love to relax on a beach in the Maldives.",
      "If I could go anywhere, I would travel through Italy.",
    ],
  ),
  Challenge(
    title: "Choose a Superpower",
    description: "If you had a superpower, what would it be? Share the reason with your partner.",
    exampleSentences: [
      "If I could have any superpower, I would choose to be able to fly.",
      "I think teleportation would be the most useful superpower.",
      "What superpower would you choose if you had the chance?",
    ],
  ),
  Challenge(
    title: "The Last Book You Read",
    description: "Tell your partner about the last book you finished or the one you are currently reading.",
    exampleSentences: [
      "I've just finished reading a book called '[Book Title]'.",
      "Currently, I'm reading a fantastic novel by [Author Name].",
      "Do you have any book recommendations?",
    ],
  ),
  Challenge(
    title: "Talk About Your Hobbies",
    description: "What do you enjoy doing in your free time? Share your hobbies with your partner.",
    exampleSentences: [
      "In my free time, I really enjoy playing the guitar.",
      "One of my hobbies is hiking in the mountains.",
      "What do you like to do for fun?",
    ],
  ),
  Challenge(
    title: "Your Most Unforgettable Memory",
    description: "Tell your partner one of the most unforgettable memories of your life.",
    exampleSentences: [
      "The most unforgettable moment of my life was when I graduated.",
      "I'll never forget the time I traveled to Paris for the first time.",
      "Do you have a special memory you'd like to share?",
    ],
  ),
  Challenge(
    title: "Future Plans",
    description: "Where do you see yourself in the next 5 years? Share your goals.",
    exampleSentences: [
      "In the next five years, I hope to start my own business.",
      "My goal is to travel to at least three new countries.",
      "What are your plans for the future?",
    ],
  ),
  Challenge(
    title: "Ask About Favorite Music",
    description: "Ask your partner about their favorite music genre and favorite artist.",
    exampleSentences: [
      "What kind of music do you usually listen to?",
      "My favorite band is [Band Name]. Have you heard of them?",
      "I'm really into rock music. Who is your favorite artist?",
    ],
  ),
  Challenge(
    title: "Time Travel",
    description: "If you had a time machine, which year would you go to and why?",
    exampleSentences: [
      "If I had a time machine, I would travel to the 1960s.",
      "I'd love to see what the future looks like in the year 2050.",
      "Which historical event would you like to witness?",
    ],
  ),
  Challenge(
    title: "An Accomplishment You're Proud Of",
    description: "What is the accomplishment in your life that you are most proud of?",
    exampleSentences: [
      "I'm most proud of learning how to speak a new language.",
      "A personal achievement I'm proud of is running a marathon.",
      "What is an accomplishment that makes you proud?",
    ],
  ),
  Challenge(
    title: "The Definition of Happiness",
    description: "Ask your partner what the word 'happiness' means to them.",
    exampleSentences: [
      "For me, happiness is spending time with my family.",
      "What does the word 'happiness' mean to you?",
      "I find happiness in small things, like reading a good book.",
    ],
  ),
  Challenge(
    title: "Your Favorite Season",
    description: "Describe your favorite season and the reasons why.",
    exampleSentences: [
      "My favorite season is autumn because of the beautiful colors.",
      "I love summer because I can go to the beach.",
      "Which season do you like the most?",
    ],
  ),
  Challenge(
    title: "Your Source of Inspiration",
    description: "Talk about a person in your life who inspires you.",
    exampleSentences: [
      "My grandmother is a huge inspiration to me.",
      "I'm really inspired by the work of [Person's Name].",
      "Is there anyone who inspires you in your life?",
    ],
  ),
  Challenge(
    title: "What Animal Would You Be?",
    description: "If you were an animal, which one would you be and why?",
    exampleSentences: [
      "If I were an animal, I would be an eagle so I could fly.",
      "I think I would be a dolphin because I love the ocean.",
      "What animal do you think best represents your personality?",
    ],
  ),
  Challenge(
    title: "Your Biggest Dream",
    description: "Share your biggest dream with your partner.",
    exampleSentences: [
      "My biggest dream is to write a book one day.",
      "I dream of traveling the world and seeing different cultures.",
      "What is a big dream you have for your life?",
    ],
  ),
  Challenge(
    title: "A Famous Dish",
    description: "Ask your partner about the most famous dish from their country or city.",
    exampleSentences: [
      "What is a famous dish from your country?",
      "You should try 'Kebab' if you ever visit Turkey.",
      "Could you describe a traditional food from where you live?",
    ],
  ),
  Challenge(
    title: "Invisibility for a Day",
    description: "What would you do if you were invisible for a day?",
    exampleSentences: [
      "If I were invisible for a day, I would probably play harmless pranks on my friends.",
      "It would be interesting to listen to what people say when they think no one is around.",
      "What would you do if you were invisible for a day?",
    ],
  ),
  Challenge(
    title: "An Interesting Fact",
    description: "Share an interesting or surprising fact you learned recently.",
    exampleSentences: [
      "Did you know that octopuses have three hearts?",
      "I recently learned an interesting fact about space.",
      "Share a fun fact that you know.",
    ],
  ),
  Challenge(
    title: "Hypothetical Questions",
    description: "Ask your partner 3 hypothetical questions starting with 'if'.",
    exampleSentences: [
      "If you could live anywhere in the world, where would it be?",
      "What would you do if you won the lottery?",
      "If you could talk to any historical figure, who would it be?",
    ],
  ),
  Challenge(
    title: "A Childhood Memory",
    description: "Share one of your favorite or funniest childhood memories.",
    exampleSentences: [
      "I remember one time when I was a kid, I tried to build a treehouse.",
      "My favorite childhood memory is going on vacation with my family.",
      "What's a funny story from your childhood?",
    ],
  ),
  Challenge(
    title: "Which Movie Character?",
    description: "If you could be a movie or TV show character, who would you be?",
    exampleSentences: [
      "If I could be any character, I would be Sherlock Holmes.",
      "I think it would be fun to be Iron Man for a day.",
      "Which character from a movie do you relate to the most?",
    ],
  ),
  Challenge(
    title: "Your Favorite Color",
    description: "Ask your partner about their favorite color and how that color makes them feel.",
    exampleSentences: [
      "What is your favorite color and why?",
      "I love the color blue because it feels calm and peaceful.",
      "How does the color green make you feel?",
    ],
  ),
  Challenge(
    title: "Describe the Word",
    description: "Choose a word (e.g., 'adventure') and ask your partner to describe it to you without using the word itself.",
    exampleSentences: [
      "Let's play a game. Can you describe the word 'adventure' without using the word itself?",
      "I'm thinking of a word. It's a feeling of great happiness and excitement...",
      "Try to explain the concept of 'liberty' to me in your own words.",
    ],
  ),
  Challenge(
    title: "A Funny Incident",
    description: "Ask your partner to tell you about a funny incident that made them laugh recently.",
    exampleSentences: [
      "What's the funniest thing that has happened to you recently?",
      "Tell me about a time you laughed a lot.",
      "I have a funny story to tell you about my cat.",
    ],
  ),
  Challenge(
    title: "Your Favorite Food",
    description: "Describe your favorite food and briefly explain how to make it.",
    exampleSentences: [
      "My all-time favorite food is lasagna.",
      "To make it, you need pasta sheets, cheese, and a tomato-based sauce.",
      "What's a dish that you absolutely love?",
    ],
  ),
  Challenge(
    title: "Teach Something",
    description: "Teach your partner a simple word or phrase in your native language.",
    exampleSentences: [
      "In Turkish, we say 'Merhaba' for 'Hello'. Can you try it?",
      "Let me teach you a useful phrase from my language.",
      "How do you say 'Thank you' in your language?",
    ],
  ),
  Challenge(
    title: "How Was Your Day?",
    description: "A classic question, but this time, describe your day using 3 new adjectives.",
    exampleSentences: [
      "My day was surprisingly productive and also quite relaxing.",
      "It was a challenging day, but ultimately rewarding.",
      "How was your day? Tell me in three adjectives.",
    ],
  ),
  Challenge(
    title: "Recommend Something",
    description: "Recommend a movie, book, or music album to your partner and explain why.",
    exampleSentences: [
      "I would highly recommend the series 'The Crown' on Netflix.",
      "You should listen to the album '[Album Name]' by [Artist Name]; it's a masterpiece.",
      "If you're looking for a good book, I suggest reading '[Book Title]'.",
    ],
  ),
  Challenge(
    title: "Do You Have a Pet?",
    description: "Ask if they have a pet. If so, describe it. If not, would you want one?",
    exampleSentences: [
      "Do you have any pets? I have a cat named Luna.",
      "I've always wanted to have a dog, maybe a Golden Retriever.",
      "If you could have any animal as a pet, what would it be?",
    ],
  ),
];