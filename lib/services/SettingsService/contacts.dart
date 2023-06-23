class Contact {
  final String name;
  final String phoneNumber;

  Contact({
    required this.name,
    required this.phoneNumber,
  });

  factory Contact.fromJSON(final Map<String, dynamic> data) => Contact(
        name: data["name"],
        phoneNumber: data["phoneNumber"],
      );

  Map<String, dynamic> toJSON() => {
        "name": name,
        "phoneNumber": phoneNumber,
      };
}
