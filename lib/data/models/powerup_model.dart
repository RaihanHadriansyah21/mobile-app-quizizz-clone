enum PowerUpType { doubleScore, freezeTimer, fiftyFifty, secondChance }

class PowerUpModel {
  final String id;
  final PowerUpType type;
  final String name;
  final String description;
  final int count;

  PowerUpModel({
    required this.id,
    required this.type,
    required this.name,
    required this.description,
    required this.count,
  });

  PowerUpModel copyWith({int? count}) {
    return PowerUpModel(
      id: id,
      type: type,
      name: name,
      description: description,
      count: count ?? this.count,
    );
  }

  static List<PowerUpModel> get defaultList => [
        PowerUpModel(
          id: 'p1',
          type: PowerUpType.doubleScore,
          name: 'Double Score 🚀',
          description: 'Get double points for the next correct answer!',
          count: 2,
        ),
        PowerUpModel(
          id: 'p2',
          type: PowerUpType.freezeTimer,
          name: 'Freeze Timer ❄️',
          description: 'Pause the countdown timer for this question.',
          count: 2,
        ),
        PowerUpModel(
          id: 'p3',
          type: PowerUpType.fiftyFifty,
          name: '50:50 ✂️',
          description: 'Remove two incorrect options.',
          count: 1,
        ),
        PowerUpModel(
          id: 'p4',
          type: PowerUpType.secondChance,
          name: 'Second Chance 🛡️',
          description: 'Get another try if you answer incorrectly.',
          count: 1,
        ),
      ];
}
