import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
part 'post.g.dart';

/// A `jsonplaceholder` post. See http://jsonplaceholder.typicode.com/posts.
@JsonSerializable()
class Post {
  const Post(
      {@required this.id,
      @required this.userId,
      @required this.title,
      @required this.body});
  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);

  final int id;
  final int userId;
  final String title;
  final String body;

  static Iterable<Post> fromJsonArray(String jsonString) =>
      json.decode(jsonString).map((map) => Post.fromJson(map));
}
