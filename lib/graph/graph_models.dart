// Base model
abstract class GraphQLModel {
  Map<String, dynamic> toJson();
}

// Tx Model
class Tx extends GraphQLModel {
  final String? hash;
  final Block? block;
  final List<TxInput>? inputs;
  final List<TxOutput>? outputs;
  final SlpGenesis? slpGenesis;
  final SlpBaton? slpBaton;

  Tx({this.hash, this.block, this.inputs, this.outputs, this.slpGenesis, this.slpBaton});

  factory Tx.fromJson(Map<String, dynamic> json) {
    return Tx(
      hash: json['hash'],
      block: json['block'] != null ? Block.fromJson(json['block']) : null,
      inputs: json['inputs'] != null ? List<TxInput>.from(json['inputs'].map((x) => TxInput.fromJson(x))) : null,
      outputs: json['outputs'] != null ? List<TxOutput>.from(json['outputs'].map((x) => TxOutput.fromJson(x))) : null,
      slpGenesis: json['slpGenesis'] != null ? SlpGenesis.fromJson(json['slpGenesis']) : null,
      slpBaton: json['slpBaton'] != null ? SlpBaton.fromJson(json['slpBaton']) : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'hash': hash,
      'block': block?.toJson(),
      'inputs': inputs?.map((x) => x.toJson()).toList(),
      'outputs': outputs?.map((x) => x.toJson()).toList(),
      'slpGenesis': slpGenesis?.toJson(),
      'slpBaton': slpBaton?.toJson(),
    };
  }

  static String get queryFields =>
      '''
    hash
    block {
      ${Block.queryFields}
    }
    inputs {
      ${TxInput.queryFields}
    }
    outputs {
      ${TxOutput.queryFields}
    }
    slpGenesis {
      ${SlpGenesis.queryFields}
    }
    slpBaton {
      ${SlpBaton.queryFields}
    }
  ''';
}

// Block Model
class Block extends GraphQLModel {
  final String? hash;
  final int? height;
  final DateTime? time;
  final List<Tx>? txs;

  Block({this.hash, this.height, this.time, this.txs});

  factory Block.fromJson(Map<String, dynamic> json) {
    return Block(
      hash: json['hash'],
      height: json['height'],
      time: json['time'] != null ? DateTime.parse(json['time']) : null,
      txs: json['txs'] != null ? List<Tx>.from(json['txs'].map((x) => Tx.fromJson(x))) : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {'hash': hash, 'height': height, 'time': time?.toIso8601String(), 'txs': txs?.map((x) => x.toJson()).toList()};
  }

  static String get queryFields => '''
    hash
    height
    time
    txs {
      hash
    }
  ''';
}

// Lock/Address Model
class Lock extends GraphQLModel {
  final String? address;
  final List<TxOutput>? outputs;
  final Profile? profile;

  Lock({this.address, this.outputs, this.profile});

  factory Lock.fromJson(Map<String, dynamic> json) {
    return Lock(
      address: json['address'],
      outputs: json['outputs'] != null ? List<TxOutput>.from(json['outputs'].map((x) => TxOutput.fromJson(x))) : null,
      profile: json['profile'] != null ? Profile.fromJson(json['profile']) : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {'address': address, 'outputs': outputs?.map((x) => x.toJson()).toList(), 'profile': profile?.toJson()};
  }

  static String get queryFields =>
      '''
    address
    outputs {
      ${TxOutput.queryFields}
    }
    profile {
      ${Profile.queryFields}
    }
  ''';
}

// Profile Model
class Profile extends GraphQLModel {
  final String? name;
  final String? pic;
  final String? address;
  final List<Post>? posts;

  Profile({this.name, this.pic, this.address, this.posts});

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      name: json['name'],
      pic: json['pic'],
      address: json['address'],
      posts: json['posts'] != null ? List<Post>.from(json['posts'].map((x) => Post.fromJson(x))) : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {'name': name, 'pic': pic, 'address': address, 'posts': posts?.map((x) => x.toJson()).toList()};
  }

  static String get queryFields =>
      '''
    name
    pic
    address
    posts {
      ${Post.queryFields}
    }
  ''';
}

// Post Model
class Post extends GraphQLModel {
  final String? hash;
  final String? text;
  final DateTime? time;
  final Lock? lock;
  final List<Like>? likes;
  final List<Follow>? follows;

  Post({this.hash, this.text, this.time, this.lock, this.likes, this.follows});

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      hash: json['hash'],
      text: json['text'],
      time: json['time'] != null ? DateTime.parse(json['time']) : null,
      lock: json['lock'] != null ? Lock.fromJson(json['lock']) : null,
      likes: json['likes'] != null ? List<Like>.from(json['likes'].map((x) => Like.fromJson(x))) : null,
      follows: json['follows'] != null ? List<Follow>.from(json['follows'].map((x) => Follow.fromJson(x))) : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'hash': hash,
      'text': text,
      'time': time?.toIso8601String(),
      'lock': lock?.toJson(),
      'likes': likes?.map((x) => x.toJson()).toList(),
      'follows': follows?.map((x) => x.toJson()).toList(),
    };
  }

  static String get queryFields => '''
    hash
    text
    time
    lock {
      address
    }
    likes {
      hash
    }
    follows {
      hash
    }
  ''';
}

// Simplified models for related types (you can expand these as needed)
class TxInput extends GraphQLModel {
  final String? hash;
  final int? index;

  TxInput({this.hash, this.index});

  factory TxInput.fromJson(Map<String, dynamic> json) {
    return TxInput(hash: json['hash'], index: json['index']);
  }

  @override
  Map<String, dynamic> toJson() => {'hash': hash, 'index': index};

  static String get queryFields => 'hash index';
}

class TxOutput extends GraphQLModel {
  final String? address;
  final int? value;
  final SlpOutput? slp;

  TxOutput({this.address, this.value, this.slp});

  factory TxOutput.fromJson(Map<String, dynamic> json) {
    return TxOutput(address: json['address'], value: json['value'], slp: json['slp'] != null ? SlpOutput.fromJson(json['slp']) : null);
  }

  @override
  Map<String, dynamic> toJson() {
    return {'address': address, 'value': value, 'slp': slp?.toJson()};
  }

  static String get queryFields =>
      '''
    address
    value
    slp {
      ${SlpOutput.queryFields}
    }
  ''';
}

class SlpGenesis extends GraphQLModel {
  final String? ticker;
  final String? name;

  SlpGenesis({this.ticker, this.name});

  factory SlpGenesis.fromJson(Map<String, dynamic> json) {
    return SlpGenesis(ticker: json['ticker'], name: json['name']);
  }

  @override
  Map<String, dynamic> toJson() => {'ticker': ticker, 'name': name};

  static String get queryFields => 'ticker name';
}

class SlpBaton extends GraphQLModel {
  final String? address;

  SlpBaton({this.address});

  factory SlpBaton.fromJson(Map<String, dynamic> json) {
    return SlpBaton(address: json['address']);
  }

  @override
  Map<String, dynamic> toJson() => {'address': address};

  static String get queryFields => 'address';
}

class SlpOutput extends GraphQLModel {
  final int? amount;

  SlpOutput({this.amount});

  factory SlpOutput.fromJson(Map<String, dynamic> json) {
    return SlpOutput(amount: json['amount']);
  }

  @override
  Map<String, dynamic> toJson() => {'amount': amount};

  static String get queryFields => 'amount';
}

class Like extends GraphQLModel {
  final String? hash;

  Like({this.hash});

  factory Like.fromJson(Map<String, dynamic> json) {
    return Like(hash: json['hash']);
  }

  @override
  Map<String, dynamic> toJson() => {'hash': hash};
}

class Follow extends GraphQLModel {
  final String? hash;

  Follow({this.hash});

  factory Follow.fromJson(Map<String, dynamic> json) {
    return Follow(hash: json['hash']);
  }

  @override
  Map<String, dynamic> toJson() => {'hash': hash};
}

class Room extends GraphQLModel {
  final String? name;
  final List<Post>? posts;

  Room({this.name, this.posts});

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(name: json['name'], posts: json['posts'] != null ? List<Post>.from(json['posts'].map((x) => Post.fromJson(x))) : null);
  }

  @override
  Map<String, dynamic> toJson() {
    return {'name': name, 'posts': posts?.map((x) => x.toJson()).toList()};
  }

  static String get queryFields =>
      '''
    name
    posts {
      ${Post.queryFields}
    }
  ''';
}
