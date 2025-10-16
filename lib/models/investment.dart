class Investment {
  String name;
  double capital;
  double returns = 0.0;
  String status = 'growing';

  Investment({required this.name, required this.capital});

  void update() {
    returns = capital * 0.01; // 1% return
  }
}