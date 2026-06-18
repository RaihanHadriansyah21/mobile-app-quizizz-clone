import '../models/user_model.dart';
import '../models/question_model.dart';
import '../models/quiz_model.dart';
import '../models/class_model.dart';
import '../models/attempt_model.dart';

class MockData {
  // Pre-configured Users
  static List<UserModel> get initialUsers => [
    UserModel(
      id: 'ac0dc55c-988b-4ef5-8383-1894288e2068',
      name: 'Administrator Utama',
      email: 'admin@quizizz.com',
      role: UserRole.admin,
      password: 'password123',
      nim: '1111111',
    ),
    UserModel(
      id: '21b5fbed-455a-494f-8120-033163fec1a4',
      name: 'Mayang, S.Pd.',
      email: 'dosen@quizizz.com',
      role: UserRole.dosen,
      password: 'password123',
      isBiometricEnabled: false,
      registeredFingerprints: ['Left Thumb', 'Right Index'],
      nim: '1985032',
    ),
    UserModel(
      id: 'bf0fb3b0-0fea-4f45-9378-82c00bd599c0',
      name: 'Budi Santoso',
      email: 'mahasiswa@quizizz.com',
      role: UserRole.mahasiswa,
      password: 'password123',
      isBiometricEnabled: false,
      registeredFingerprints: [],
      nim: '2203001',
    ),
    UserModel(
      id: 'u_mahasiswa2',
      name: 'Ani Lestari',
      email: 'ani@quizizz.com',
      role: UserRole.mahasiswa,
      password: 'password123',
      nim: '2203002',
    ),
  ];

  // Pre-configured Quizzes
  static List<QuizModel> get initialQuizzes => [
    QuizModel(
      id: 'q_tatasurya',
      title: 'Kuis IPA: Sistem Tata Surya 🪐',
      description:
          'Uji pemahaman Anda mengenai planet-planet di galaksi Bima Sakti secara mandiri.',
      creatorId: '21b5fbed-455a-494f-8120-033163fec1a4',
      isHomework: false,
      isTimerEnabled: true,
      questions: [
        QuestionModel(
          id: 'q_ts_1',
          text: 'Planet manakah yang paling dekat dengan Matahari?',
          type: QuestionType.multipleChoice,
          options: ['Venus', 'Merkurius', 'Bumi', 'Mars'],
          correctAnswer: 'Merkurius',
          points: 100,
          timeLimitSeconds: 20,
        ),
        QuestionModel(
          id: 'q_ts_2',
          text: 'Planet Mars sering dijuluki sebagai Planet Merah.',
          type: QuestionType.trueFalse,
          options: ['Benar', 'Salah'],
          correctAnswer: 'Benar',
          points: 100,
          timeLimitSeconds: 15,
        ),
        QuestionModel(
          id: 'q_ts_3',
          text: 'Planet terbesar di tata surya kita adalah...',
          type: QuestionType.openEnded,
          correctAnswer: 'Jupiter',
          points: 150,
          timeLimitSeconds: 30,
        ),
        QuestionModel(
          id: 'q_ts_4',
          text: 'Urutan planet setelah Bumi adalah Mars, kemudian Jupiter.',
          type: QuestionType.trueFalse,
          options: ['Benar', 'Salah'],
          correctAnswer: 'Benar',
          points: 100,
          timeLimitSeconds: 15,
        ),
      ],
    ),
    QuizModel(
      id: 'q_math',
      title: 'Tugas Matematika: Aljabar Dasar 📐',
      description:
          'Pekerjaan Rumah (Homework) Aljabar Dasar. Kerjakan dengan teliti tanpa batasan waktu.',
      creatorId: '21b5fbed-455a-494f-8120-033163fec1a4',
      isHomework: true,
      deadline: DateTime.now().add(const Duration(days: 7)),
      isTimerEnabled: false,
      questions: [
        QuestionModel(
          id: 'q_mt_1',
          text: 'Jika 2x + 5 = 15, berapakah nilai x?',
          type: QuestionType.multipleChoice,
          options: ['3', '5', '10', '2'],
          correctAnswer: '5',
          points: 100,
          timeLimitSeconds: 0,
        ),
        QuestionModel(
          id: 'q_mt_2',
          text: 'Hasil perkalian dari (x + 2)(x - 2) adalah x² - 4.',
          type: QuestionType.trueFalse,
          options: ['Benar', 'Salah'],
          correctAnswer: 'Benar',
          points: 120,
          timeLimitSeconds: 0,
        ),
        QuestionModel(
          id: 'q_mt_3',
          text: 'Berapa nilai y jika 3y - 6 = y + 4?',
          type: QuestionType.openEnded,
          correctAnswer: '5',
          points: 150,
          timeLimitSeconds: 0,
        ),
      ],
    ),
    QuizModel(
      id: 'q_english',
      title: 'English Listening & Meme Trivia 🎧',
      description:
          'Practice English with audio clips and funny reaction memes!',
      creatorId: '21b5fbed-455a-494f-8120-033163fec1a4',
      isHomework: false,
      isTimerEnabled: true,
      questions: [
        QuestionModel(
          id: 'q_eng_1',
          text: 'Dengarkan klip suara dan tentukan emosi pembicara.',
          type: QuestionType.multipleChoice,
          options: ['Happy', 'Sad', 'Angry', 'Excited'],
          correctAnswer: 'Happy',
          audioPath: 'mock_audio_happy.mp3',
          points: 100,
          timeLimitSeconds: 45,
        ),
        QuestionModel(
          id: 'q_eng_2',
          text: 'Look at the picture. What is the programmer doing?',
          type: QuestionType.multipleChoice,
          options: ['Fixing bugs', 'Sleeping', 'Crying', 'Drinking coffee'],
          correctAnswer: 'Drinking coffee',
          imagePath: 'mock_programmer_meme.jpg',
          points: 100,
          timeLimitSeconds: 30,
        ),
      ],
    ),
  ];

  // Pre-configured Classes
  static List<ClassModel> get initialClasses => [
    ClassModel(
      id: 'c_class10a',
      className: 'Kelas X-A (IPA)',
      code: '102948',
      teacherId: '21b5fbed-455a-494f-8120-033163fec1a4',
      studentIds: ['bf0fb3b0-0fea-4f45-9378-82c00bd599c0', 'u_mahasiswa2'],
      quizIds: ['q_tatasurya', 'q_english'],
    ),
    ClassModel(
      id: 'c_class10b',
      className: 'Kelas X-B (IPS)',
      code: '459203',
      teacherId: '21b5fbed-455a-494f-8120-033163fec1a4',
      studentIds: ['bf0fb3b0-0fea-4f45-9378-82c00bd599c0'],
      quizIds: ['q_math'],
    ),
  ];

  // Preloaded Attempts for Analytics
  static List<AttemptModel> get initialAttempts => [
    AttemptModel(
      id: 'a_att1',
      studentId: 'bf0fb3b0-0fea-4f45-9378-82c00bd599c0',
      studentName: 'Budi Santoso',
      quizId: 'q_tatasurya',
      score: 350,
      totalQuestions: 4,
      correctAnswersCount: 3,
      completedAt: DateTime.now().subtract(const Duration(hours: 3)),
      answers: {
        'q_ts_1': 'Merkurius',
        'q_ts_2': 'Benar',
        'q_ts_3': 'Saturnus',
        'q_ts_4': 'Benar',
      },
    ),
    AttemptModel(
      id: 'a_att2',
      studentId: 'u_mahasiswa2',
      studentName: 'Ani Lestari',
      quizId: 'q_tatasurya',
      score: 450,
      totalQuestions: 4,
      correctAnswersCount: 4,
      completedAt: DateTime.now().subtract(const Duration(hours: 2)),
      answers: {
        'q_ts_1': 'Merkurius',
        'q_ts_2': 'Benar',
        'q_ts_3': 'Jupiter',
        'q_ts_4': 'Benar',
      },
    ),
    AttemptModel(
      id: 'a_att3',
      studentId: 'bf0fb3b0-0fea-4f45-9378-82c00bd599c0',
      studentName: 'Budi Santoso',
      quizId: 'q_english',
      score: 100,
      totalQuestions: 2,
      correctAnswersCount: 1,
      completedAt: DateTime.now().subtract(const Duration(hours: 1)),
      answers: {'q_eng_1': 'Happy', 'q_eng_2': 'Crying'},
    ),
  ];

  // Reusable Question Bank pool (standalone questions, with category & level).
  static List<QuestionModel> get initialQuestions => [
    QuestionModel(
      id: 'qb_mtk_1',
      text: 'Berapakah hasil dari 7 × 8?',
      type: QuestionType.multipleChoice,
      options: ['54', '56', '64', '48'],
      correctAnswer: '56',
      points: 100,
      timeLimitSeconds: 20,
      category: 'Matematika',
      difficulty: 'Mudah',
    ),
    QuestionModel(
      id: 'qb_mtk_2',
      text: 'Akar kuadrat dari 144 adalah...',
      type: QuestionType.openEnded,
      correctAnswer: '12',
      points: 150,
      timeLimitSeconds: 30,
      category: 'Matematika',
      difficulty: 'Sedang',
    ),
    QuestionModel(
      id: 'qb_ipa_1',
      text: 'Air mendidih pada suhu 100°C di tekanan 1 atm.',
      type: QuestionType.trueFalse,
      options: ['Benar', 'Salah'],
      correctAnswer: 'Benar',
      points: 100,
      timeLimitSeconds: 15,
      category: 'IPA',
      difficulty: 'Mudah',
    ),
    QuestionModel(
      id: 'qb_ipa_2',
      text:
          'Organel sel yang berperan sebagai "pembangkit tenaga" sel adalah...',
      type: QuestionType.multipleChoice,
      options: ['Ribosom', 'Mitokondria', 'Nukleus', 'Vakuola'],
      correctAnswer: 'Mitokondria',
      points: 120,
      timeLimitSeconds: 25,
      category: 'IPA',
      difficulty: 'Sedang',
    ),
    QuestionModel(
      id: 'qb_eng_1',
      text: 'Choose the correct past tense of "go".',
      type: QuestionType.multipleChoice,
      options: ['goed', 'went', 'gone', 'going'],
      correctAnswer: 'went',
      points: 100,
      timeLimitSeconds: 20,
      category: 'Bahasa Inggris',
      difficulty: 'Mudah',
    ),
    QuestionModel(
      id: 'qb_umum_1',
      text: 'Ibu kota Indonesia adalah...',
      type: QuestionType.openEnded,
      correctAnswer: 'Jakarta',
      points: 100,
      timeLimitSeconds: 20,
      category: 'Umum',
      difficulty: 'Mudah',
    ),
    QuestionModel(
      id: 'qb_mtk_3',
      text: 'Jika f(x) = 2x² - 3x + 1, berapakah f(2)?',
      type: QuestionType.openEnded,
      correctAnswer: '3',
      points: 200,
      timeLimitSeconds: 45,
      category: 'Matematika',
      difficulty: 'Sulit',
    ),
  ];
}
