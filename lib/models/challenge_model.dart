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

// 30 farklı görev, başlıkları ve örnek cümleleri ile birlikte
const List<Challenge> challenges = [
  Challenge(
    title: "En Sevdiğin Filmi Anlat",
    description: "Bugün tanıştığın partnere en sevdiğin filmi ve neden sevdiğini anlat.",
    exampleSentences: [
      "Have you ever seen the movie '[Film Adı]'? It's my favorite.",
      "I really love '[Film Adı]' because the story is amazing.",
      "If you like [Film Türü] movies, you should definitely watch '[Film Adı]'.",
    ],
  ),
  Challenge(
    title: "5 Yeni Kelime Kullan",
    description: "Bugünkü sohbetinde daha önce kullanmadığın 5 yeni İngilizce kelime kullanmaya çalış.",
    exampleSentences: [
      "I learned a new word today, it's 'serendipity'.",
      "Let me try to use this word in a sentence...",
      "Could you tell me if I'm using the word 'ubiquitous' correctly?",
    ],
  ),
  Challenge(
    title: "Hayalindeki Tatili Tarif Et",
    description: "Gözlerini kapat ve gitmek istediğin o mükemmel tatili partnerine anlat.",
    exampleSentences: [
      "My dream vacation would be a trip to Japan.",
      "I would love to relax on a beach in the Maldives.",
      "If I could go anywhere, I would travel through Italy.",
    ],
  ),
  Challenge(
    title: "Bir Süper Güç Seç",
    description: "Bir süper gücün olsaydı ne olurdu? Nedenini partnerinle paylaş.",
    exampleSentences: [
      "If I could have any superpower, I would choose to be able to fly.",
      "I think teleportation would be the most useful superpower.",
      "What superpower would you choose if you had the chance?",
    ],
  ),
  Challenge(
    title: "En Son Okuduğun Kitap",
    description: "En son bitirdiğin kitabı veya şu an okuduğun kitabı partnerine anlat.",
    exampleSentences: [
      "I've just finished reading a book called '[Kitap Adı]'.",
      "Currently, I'm reading a fantastic novel by [Yazar Adı].",
      "Do you have any book recommendations?",
    ],
  ),
  // Buraya diğer 25 görevi de benzer şekilde ekleyebilirsiniz.
  // ... (Listenin devamı)
  Challenge(
    title: "Hobilerinden Bahset",
    description: "Boş zamanlarında ne yapmaktan hoşlanırsın? Hobilerini partnerinle paylaş.",
    exampleSentences: [
      "In my free time, I really enjoy playing the guitar.",
      "One of my hobbies is hiking in the mountains.",
      "What do you like to do for fun?",
    ],
  ),
  Challenge(
    title: "En Unutamadığın Anı",
    description: "Hayatındaki en unutulmaz anılardan birini partnerine anlat.",
    exampleSentences: [
      "The most unforgettable moment of my life was when I graduated.",
      "I'll never forget the time I traveled to Paris for the first time.",
      "Do you have a special memory you'd like to share?",
    ],
  ),
  Challenge(
    title: "Gelecek Planları",
    description: "Gelecekteki 5 yıl içinde kendini nerede görüyorsun? Hedeflerini paylaş.",
    exampleSentences: [
      "In the next five years, I hope to start my own business.",
      "My goal is to travel to at least three new countries.",
      "What are your plans for the future?",
    ],
  ),
  Challenge(
    title: "En Sevdiği Müzik",
    description: "Partnerine en sevdiği müzik türünü ve favori sanatçısını sor.",
    exampleSentences: [
      "What kind of music do you usually listen to?",
      "My favorite band is [Grup Adı]. Have you heard of them?",
      "I'm really into rock music. Who is your favorite artist?",
    ],
  ),
  Challenge(
    title: "Zaman Yolculuğu",
    description: "Bir zaman makinen olsaydı hangi yıla giderdin ve neden?",
    exampleSentences: [
      "If I had a time machine, I would travel to the 1960s.",
      "I'd love to see what the future looks like in the year 2050.",
      "Which historical event would you like to witness?",
    ],
  ),
  Challenge(
    title: "Gurur Duyduğun Başarı",
    description: "Hayatında en çok gurur duyduğun başarın nedir?",
    exampleSentences: [
      "I'm most proud of learning how to speak a new language.",
      "A personal achievement I'm proud of is running a marathon.",
      "What is an accomplishment that makes you proud?",
    ],
  ),
  Challenge(
    title: "Mutluluğun Tanımı",
    description: "Partnerine 'mutluluk' kelimesinin onun için ne anlama geldiğini sor.",
    exampleSentences: [
      "For me, happiness is spending time with my family.",
      "What does the word 'happiness' mean to you?",
      "I find happiness in small things, like reading a good book.",
    ],
  ),
  Challenge(
    title: "En Sevdiğin Mevsim",
    description: "En sevdiğin mevsimi ve nedenlerini anlat.",
    exampleSentences: [
      "My favorite season is autumn because of the beautiful colors.",
      "I love summer because I can go to the beach.",
      "Which season do you like the most?",
    ],
  ),
  Challenge(
    title: "İlham Kaynağın",
    description: "Hayatında sana ilham veren bir kişiden bahset.",
    exampleSentences: [
      "My grandmother is a huge inspiration to me.",
      "I'm really inspired by the work of [Kişi Adı].",
      "Is there anyone who inspires you in your life?",
    ],
  ),
  Challenge(
    title: "Hangi Hayvan Olurdun?",
    description: "Bir hayvan olsan hangisi olurdun ve neden?",
    exampleSentences: [
      "If I were an animal, I would be an eagle so I could fly.",
      "I think I would be a dolphin because I love the ocean.",
      "What animal do you think best represents your personality?",
    ],
  ),
  Challenge(
    title: "En Büyük Hayalin",
    description: "En büyük hayalini partnerinle paylaş.",
    exampleSentences: [
      "My biggest dream is to write a book one day.",
      "I dream of traveling the world and seeing different cultures.",
      "What is a big dream you have for your life?",
    ],
  ),
  Challenge(
    title: "Meşhur Bir Yemek",
    description: "Partnerine ülkesindeki veya şehrindeki en meşhur yemeği sor.",
    exampleSentences: [
      "What is a famous dish from your country?",
      "You should try 'Kebab' if you ever visit Turkey.",
      "Could you describe a traditional food from where you live?",
    ],
  ),
  Challenge(
    title: "Bir Günlüğüne Görünmezlik",
    description: "Bir günlüğüne görünmez olsan ne yapardın?",
    exampleSentences: [
      "If I were invisible for a day, I would probably play harmless pranks on my friends.",
      "It would be interesting to listen to what people say when they think no one is around.",
      "What would you do if you were invisible for a day?",
    ],
  ),
  Challenge(
    title: "İlginç Bir Bilgi",
    description: "En son öğrendiğin ilginç veya şaşırtıcı bir bilgiyi anlat.",
    exampleSentences: [
      "Did you know that octopuses have three hearts?",
      "I recently learned an interesting fact about space.",
      "Share a fun fact that you know.",
    ],
  ),
  Challenge(
    title: "Varsayımsal Sorular",
    description: "Partnerine 'eğer' ile başlayan 3 tane varsayımsal soru sor.",
    exampleSentences: [
      "If you could live anywhere in the world, where would it be?",
      "What would you do if you won the lottery?",
      "If you could talk to any historical figure, who would it be?",
    ],
  ),
  Challenge(
    title: "Çocukluk Anısı",
    description: "En sevdiğin veya en komik çocukluk anılarından birini anlat.",
    exampleSentences: [
      "I remember one time when I was a kid, I tried to build a treehouse.",
      "My favorite childhood memory is going on vacation with my family.",
      "What's a funny story from your childhood?",
    ],
  ),
  Challenge(
    title: "Hangi Film Karakteri?",
    description: "Bir film veya dizi karakteri olsan kim olurdun?",
    exampleSentences: [
      "If I could be any character, I would be Sherlock Holmes.",
      "I think it would be fun to be Iron Man for a day.",
      "Which character from a movie do you relate to the most?",
    ],
  ),
  Challenge(
    title: "En Sevdiğin Renk",
    description: "Partnerine en sevdiği rengi ve o rengin onda ne hissettirdiğini sor.",
    exampleSentences: [
      "What is your favorite color and why?",
      "I love the color blue because it feels calm and peaceful.",
      "How does the color green make you feel?",
    ],
  ),
  Challenge(
    title: "Kelimeyi Anlat",
    description: "Bir kelime seç (örneğin 'macera') ve partnerinden o kelimeyi kullanmadan sana anlatmasını iste.",
    exampleSentences: [
      "Let's play a game. Can you describe the word 'adventure' without using the word itself?",
      "I'm thinking of a word. It's a feeling of great happiness and excitement...",
      "Try to explain the concept of 'liberty' to me in your own words.",
    ],
  ),
  Challenge(
    title: "Komik Bir Olay",
    description: "Partnerine son zamanlarda güldüğü komik bir olayı anlatmasını sor.",
    exampleSentences: [
      "What's the funniest thing that has happened to you recently?",
      "Tell me about a time you laughed a lot.",
      "I have a funny story to tell you about my cat.",
    ],
  ),
  Challenge(
    title: "En Sevdiğin Yemek",
    description: "En sevdiğin yemeğin ne olduğunu ve basitçe nasıl yapıldığını anlat.",
    exampleSentences: [
      "My all-time favorite food is lasagna.",
      "To make it, you need pasta sheets, cheese, and a tomato-based sauce.",
      "What's a dish that you absolutely love?",
    ],
  ),
  Challenge(
    title: "Bir Şey Öğret",
    description: "Partnerine kendi dilinde basit bir kelime veya cümle öğret.",
    exampleSentences: [
      "In Turkish, we say 'Merhaba' for 'Hello'. Can you try it?",
      "Let me teach you a useful phrase from my language.",
      "How do you say 'Thank you' in your language?",
    ],
  ),
  Challenge(
    title: "Günün Nasıl Geçti?",
    description: "Klasik bir soru, ama bu sefer 3 yeni sıfat kullanarak gününü anlat.",
    exampleSentences: [
      "My day was surprisingly productive and also quite relaxing.",
      "It was a challenging day, but ultimately rewarding.",
      "How was your day? Tell me in three adjectives.",
    ],
  ),
  Challenge(
    title: "Bir Şey Tavsiye Et",
    description: "Partnerine bir film, kitap veya müzik albümü tavsiye et ve nedenini açıkla.",
    exampleSentences: [
      "I would highly recommend the series 'The Crown' on Netflix.",
      "You should listen to the album '[Album Adı]' by [Sanatçı Adı]; it's a masterpiece.",
      "If you're looking for a good book, I suggest reading '[Kitap Adı]'.",
    ],
  ),
  Challenge(
    title: "Evcil Hayvanın Var Mı?",
    description: "Bir evcil hayvanın olup olmadığını sor. Varsa onu tarif et, yoksa bir tane ister miydin?",
    exampleSentences: [
      "Do you have any pets? I have a cat named Luna.",
      "I've always wanted to have a dog, maybe a Golden Retriever.",
      "If you could have any animal as a pet, what would it be?",
    ],
  ),
];