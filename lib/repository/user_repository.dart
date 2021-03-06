import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dubs_app/common/common_errors.dart';
import 'package:dubs_app/logger/log_printer.dart';
import 'package:dubs_app/model/user.dart';
import 'package:dubs_app/model/user_search_result.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Firestore _store = Firestore.instance;

  final _logger = getLogger("UserRepository");

  // First time sign in creating a user with email and password
  Future<User> createUser(String email, String password) async {
    _logger.d("createUser- Entered create user with email '" +
        checkAndPrint(email) +
        "' and a password");

    // check that user is not signed in
    var currentUser = await _auth.currentUser();
    if (currentUser != null) {
      _logger.e("loginUser- A user is already signed in!");
      return Future.error("User is already signed in. Please log out");
    }

    // attempt to create the user
    AuthResult result;
    try {
      result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
    } catch (e) {
      _logger.w("createUser- Caught exception when adding user. Message '" +
          e.toString() +
          "'");
      return Future.error(e.toString());
    }

    // send email verification
    try {
      await result.user.sendEmailVerification();
    } catch (e) {
      _logger.w("createUser- Failed to send email to user. Message '" +
          e.toString() +
          "'");
    }
    return User(result.user.uid, result.user.email, null, null,
        UserAuthState.NOT_VERIFIED);
  }

  // Logging in a user with an email and password
  Future<User> loginUser(String email, String password) async {
    _logger.d("loginUser- Entered login user with email '" +
        checkAndPrint(email) +
        "' and a password");
    var currentUser = await _auth.currentUser();
    if (currentUser != null) {
      _logger.e("loginUser- A user is already signed in!");
      return Future.error("User is already signed in. Please logout");
    }
    AuthResult result;
    try {
      result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
    } catch (e) {
      _logger.w("loginUser- Failed to login! Error: '" + e.toString() + "'");
      return Future.error("Failed to login! Error: " + e.toString());
    }

    return await _userFromFirebase(result.user);
  }

  // Gets the user object from the current user
  // errors if the user is not signed in
  Future<User> getUser() async {
    _logger.d("getUser- Entered");
    final user = await _auth.currentUser();
    if (user == null) {
      _logger.e("getUser- User is not signed in");
      return Future.error("User is not signed in");
    }
    return await _userFromFirebase(user);
  }

  // is the user logged in
  Future<bool> isLoggedIn() async {
    return (await _auth.currentUser()) != null;
  }

  // sends an email verification to the user
  Future<void> sendEmailVerification() async {
    _logger.d("sendEmailVerification- Entered");
    try {
      // grab the current user
      final user = await _auth.currentUser();
      if (user == null) {
        _logger.e("sendEmailVerification- User is not signed in");
        return Future.error("User is not signed in");
      }
      // send email verification
      await user.sendEmailVerification();
    } catch (e) {
      _logger.e("sendEmailVerification- Failed to send email. Error '" +
          e.toString() +
          "'");
      return Future.error(e.toString());
    }
  }

  // sets the user specific information
  Future<User> setUserData(MutableUserData userInfo) async {
    _logger.v("setUserData- Entered");
    if (userInfo.username == null) {
      _logger.e("setUserData- No username");
      return Future.error("No username is set");
    }
    final user = await _auth.currentUser();
    if (user == null) {
      _logger.e("setUserData- User is not signed in");
      return Future.error("User is not signed in");
    }

    _logger.v("setUserData- Setting user data");
    String usernameId = userInfo.username.toLowerCase();

    // TODO- hack for full text search and pagination
    _logger.v("setUserData- Generating username tokens");
    List<String> usernameSearchTokens = List<String>();
    String currentSearchToken = "";
    for (int i = 0; i < usernameId.length; i++) {
      currentSearchToken += usernameId[i];
      usernameSearchTokens.add(currentSearchToken);
    }
    bool usernameTaken = false;
    try {
      await _store.runTransaction((transaction) async {
        DocumentSnapshot username = await transaction
            .get(_store.collection("usernames").document(usernameId));
        if (username.exists) {
          _logger.i("setUserData- username already exists");
          usernameTaken = true;
          return Future.error("Username is taken");
        }
        await transaction
            .set(_store.collection("usernames").document(usernameId), {
          "userid": user.uid,
          "displayName": userInfo.username,
          "searchTokens": usernameSearchTokens
        });
        return transaction.set(_store.collection("users").document(user.uid),
            {"username": usernameId});
      });
    } catch (e) {
      _logger.e("setUserData- Caught error when running transaction '" +
          e.toString() +
          "'");
      return Future.error(e.toString());
    }

    if (usernameTaken) {
      return Future.error("username is taken");
    }

    return await getUser();
  }

  // Search for friends given a limit to the response back and a startAfter username for pagination
  Future<List<UserSearchResult>> searchForFriends(
      String searchString, int limit, String startAfter) async {
    _logger.v("searchForFriends- Entered");
    final user = await _auth.currentUser();
    if (user == null) {
      _logger.e("searchForFriends- User is not signed in");
      return Future.error("User is not signed in");
    }

    // 1) search for the username in the database
    String normalizedSearch = searchString.toLowerCase();
    int searchLimit =
        limit + 1; // just in case the username search grabs the current user
    Query currQ;
    if (startAfter != null) {
      currQ = _store
          .collection("usernames")
          .orderBy(FieldPath.documentId)
          .startAfter([startAfter.toLowerCase()])
          .where("searchTokens", arrayContains: normalizedSearch)
          .limit(searchLimit);
    } else {
      currQ = _store
          .collection("usernames")
          .orderBy(FieldPath.documentId)
          .where("searchTokens", arrayContains: normalizedSearch)
          .limit(searchLimit);
    }
    QuerySnapshot usernameSearchQ;
    try {
      usernameSearchQ = await currQ.getDocuments();
    } catch (e) {
      _logger.e(
          "searchForFriends- caught error when searching usernames ${e.toString()}");
      return Future.error("Username query failed ${e.toString()}");
    }
    _logger.v(
        "searchForFriends- got ${usernameSearchQ.documents.length} search results back");
    List<UserSearchResult> searchResults = List<UserSearchResult>();
    if (usernameSearchQ.documents.isEmpty) {
      _logger.v(
          "searchForFriends- username search returned no results with search ${normalizedSearch}");
      return searchResults;
    }

    // 2) search through the users existing friend requests
    DocumentSnapshot friendRequestQ;
    try {
      friendRequestQ =
          await _store.collection("friend_requests").document(user.uid).get();
    } catch (e) {
      _logger.w(
          "searchForFriends- friend requests search returned with error ${e.toString()}");
      return Future.error(
          "A network error ocurred. Make sure your connection is fine");
    }
    _logger.v("searchForFriends- friend request query returned");

    // 3) search through the users existing friends
    DocumentSnapshot friendsQ;
    try {
      friendsQ = await _store.collection("friends").document(user.uid).get();
    } catch (e) {
      _logger.w(
          "searchForFriends- friends search returned with error ${e.toString()}");
      return Future.error(
          "A network error ocurred. Make sure your connection is fine");
    }
    _logger.v("searchForFriends- friends query returned");

    // 4) compare the existing friend requests and friends with the search results
    for (int i = 0;
        i < usernameSearchQ.documents.length && searchResults.length < limit;
        i++) {
      String currSearchId = usernameSearchQ.documents[i].data["userid"];
      UserRelationshipState relationship;
      if (currSearchId == user.uid) {
        _logger.v("searchForFriends- current user so skip");
        continue;
      } else if (friendsQ.data != null &&
          friendsQ.data.containsKey(currSearchId)) {
        relationship = UserRelationshipState.FRIENDS;
      } else if (friendRequestQ.data != null &&
          friendRequestQ.data.containsKey(currSearchId)) {
        relationship = UserSearchResult.friendRequestStringToEnum(
            friendRequestQ.data[currSearchId]);
      } else {
        relationship = UserRelationshipState.NOT_FRIENDS;
      }
      searchResults.add(UserSearchResult(currSearchId,
          usernameSearchQ.documents[i].data["displayName"], relationship));
    }
    // return a list of users
    return searchResults;
  }

  Future<void> sendFriendRequest(String friendsId) async {
    _logger.v("sendFriendRequest- Entered");
    final user = await _auth.currentUser();
    if (user == null) {
      _logger.e("sendFriendRequest- User is not signed in");
      return Future.error("User is not signed in");
    }

    if (user.uid == friendsId) {
      _logger.e("sendFriendRequest- Cannot send a friend request to yourself");
      return Future.error("Cannot send a friend request to yourself");
    }

    try {
      await _store.runTransaction((transaction) async {
        DocumentSnapshot userSnapshot = await transaction
            .get(_store.collection("friend_requests").document(user.uid));
        DocumentSnapshot otherSnapshot = await transaction
            .get(_store.collection("friend_requests").document(friendsId));
        // update our mapping
        if (!userSnapshot.exists) {
          await transaction
              .set(_store.collection("friend_requests").document(user.uid), {
            friendsId: UserSearchResult.friendRequestEnumToString(
                UserRelationshipState.OUTSTANDING_INVITE)
          });
        } else {
          await transaction
              .update(_store.collection("friend_requests").document(user.uid), {
            friendsId: UserSearchResult.friendRequestEnumToString(
                UserRelationshipState.OUTSTANDING_INVITE)
          });
        }
        // update the other user's mapping
        if (!otherSnapshot.exists) {
          return await transaction
              .set(_store.collection("friend_requests").document(friendsId), {
            user.uid: UserSearchResult.friendRequestEnumToString(
                UserRelationshipState.INCOMING_INVITE)
          });
        } else {
          return await transaction.update(
              _store.collection("friend_requests").document(friendsId), {
            user.uid: UserSearchResult.friendRequestEnumToString(
                UserRelationshipState.INCOMING_INVITE)
          });
        }
      });
    } catch (e) {
      _logger.e("sendFriendRequest- Caught error when running transaction '" +
          e.toString() +
          "'");
      return Future.error(e.toString());
    }
    return;
  }

  Future<void> acceptFriendRequest(String friendsId) async {
    _logger.v("acceptFriendRequest- Entered");
    final user = await _auth.currentUser();
    if (user == null) {
      _logger.e("acceptFriendRequest- User is not signed in");
      return Future.error("User is not signed in");
    }

    if (user.uid == friendsId) {
      _logger
          .e("acceptFriendRequest- Cannot accept a friend request to yourself");
      return Future.error("Cannot accept a friend request to yourself");
    }

    try {
      await _store.runTransaction((transaction) async {
        // grab user document
        DocumentSnapshot friendRequestSnapshot = await transaction
            .get(_store.collection("friend_requests").document(user.uid));
        // sanity check
        if (!friendRequestSnapshot.exists) {
          _logger.e("acceptFriendRequest- no friend requests available");
          return Future.error("no friend requests available");
        }
        if (!friendRequestSnapshot.data.containsKey(friendsId)) {
          _logger.e("acceptFriendRequest- friend request could not be found");
          return Future.error("friend request could not be found");
        }
        // grab the other friends document
        DocumentSnapshot otherFriendRequestSnapshot = await transaction
            .get(_store.collection("friend_requests").document(friendsId));
        // sanity check
        if (!otherFriendRequestSnapshot.exists) {
          _logger.e(
              "acceptFriendRequest- couldn't find the other friend's mapping");
          return Future.error("no friend requests available");
        }
        if (!otherFriendRequestSnapshot.data.containsKey(user.uid)) {
          _logger.e(
              "acceptFriendRequest- friend request could not be found in the other mapping");
          return Future.error("friend request could not be found");
        }

        DocumentSnapshot friendSnapshot = await transaction
            .get(_store.collection("friends").document(user.uid));
        DocumentSnapshot otherUserFriendsSnapshot = await transaction
            .get(_store.collection("friends").document(friendsId));

        if (UserSearchResult.friendRequestStringToEnum(
                friendRequestSnapshot.data[friendsId]) !=
            UserRelationshipState.INCOMING_INVITE) {
          _logger.e(
              "acceptFriendRequest- friend request is not an incoming invite ${friendRequestSnapshot.data[friendsId]}");
          return Future.error("Friend request no longer is available");
        }

        // delete the friend request
        var newData = friendRequestSnapshot.data;
        newData.remove(friendsId);
        await transaction.set(
            _store.collection("friend_requests").document(user.uid), newData);

        // delete the other users friend request
        var otherNewData = friendRequestSnapshot.data;
        otherNewData.remove(user.uid);
        await transaction.set(
            _store.collection("friend_requests").document(friendsId),
            otherNewData);

        // update our mapping
        if (friendSnapshot.exists) {
          await transaction.update(
              _store.collection("friends").document(user.uid),
              {friendsId: true});
        } else {
          await transaction.set(_store.collection("friends").document(user.uid),
              {friendsId: true});
        }
        // update the other user's mapping
        if (otherUserFriendsSnapshot.exists) {
          return await transaction.update(
              _store.collection("friends").document(friendsId),
              {user.uid: true});
        }
        return await transaction.set(
            _store.collection("friends").document(friendsId), {user.uid: true});
      });
    } catch (e) {
      _logger.e("acceptFriendRequest- Caught error when running transaction '" +
          e.toString() +
          "'");
      return Future.error(e.toString());
    }
    return;
  }

  Future<void> declineFriendRequest(String friendsId) async {
    _logger.v("declineFriendRequest- Entered");
    final user = await _auth.currentUser();
    if (user == null) {
      _logger.e("declineFriendRequest- User is not signed in");
      return Future.error("User is not signed in");
    }

    if (user.uid == friendsId) {
      _logger.e(
          "declineFriendRequest- Cannot decline a friend request to yourself");
      return Future.error("Cannot declien a friend request to yourself");
    }

    try {
      await _store.runTransaction((transaction) async {
        // grab user document
        DocumentSnapshot friendRequestSnapshot = await transaction
            .get(_store.collection("friend_requests").document(user.uid));
        // sanity check
        if (!friendRequestSnapshot.exists) {
          _logger.e("declineFriendRequest- friend request no longer exists");
          return Future.error("Friend request no longer exists");
        }
        if (!friendRequestSnapshot.data.containsKey(friendsId)) {
          _logger.e("declineFriendRequest- friend request could not be found");
          return Future.error("friend request could not be found");
        }
        // grab other users document
        DocumentSnapshot otherFriendRequestSnapshot = await transaction
            .get(_store.collection("friend_requests").document(friendsId));
        // sanity check
        if (!otherFriendRequestSnapshot.exists) {
          _logger.e(
              "declineFriendRequest- friend request no longer exists from the other user");
          return Future.error("Friend request no longer exists");
        }
        if (!otherFriendRequestSnapshot.data.containsKey(user.uid)) {
          _logger.e(
              "declineFriendRequest- friend request could not be found from the other user");
          return Future.error("friend request could not be found");
        }

        // must be an incoming invite
        if (UserSearchResult.friendRequestStringToEnum(
                friendRequestSnapshot.data[friendsId]) !=
            UserRelationshipState.INCOMING_INVITE) {
          _logger.e(
              "declineFriendRequest- friend request is not an incoming invite ${friendRequestSnapshot.data[friendsId]}");
          return Future.error("Friend request no longer is available");
        }

        // delete the friend request
        var ourData = friendRequestSnapshot.data;
        ourData.remove(friendsId);
        await transaction.set(
            _store.collection("friend_requests").document(user.uid), ourData);
        // delete the other user's mapping
        var otherData = otherFriendRequestSnapshot.data;
        otherData.remove(user.uid);
        return await transaction.set(
            _store.collection("friend_requests").document(friendsId),
            otherData);
      });
    } catch (e) {
      _logger.e(
          "declineFriendRequest- Caught error when running transaction '" +
              e.toString() +
              "'");
      return Future.error(e.toString());
    }
    return;
  }

  Future<void> logout() async {
    _logger.v("logout- logging out");
    if (!await isLoggedIn()) {
      _logger.d("logout- user is not logged in");
      return;
    }
    return await _auth.signOut();
  }

  // reloads the user and their information
  Future<User> reloadUser() async {
    _logger.d("reloadUser- Enter");
    final user = await _auth.currentUser();
    if (user == null) {
      _logger.e("reloadUser- User is not logged in");
      return Future.error("User is not logged in");
    }
    await user.reload();
    return await getUser();
  }

  // private function to convert the firebase user to our internal user
  Future<User> _userFromFirebase(FirebaseUser fbUser) async {
    _logger.v("_userFromFirebase- entering with uid '" + fbUser.uid + "'");
    if (!fbUser.isEmailVerified) {
      _logger.v("_userFromFirebase- email is not verified");
      return User(
          fbUser.uid, fbUser.email, null, null, UserAuthState.NOT_VERIFIED);
    }
    List<DocumentSnapshot> documentQuery;
    try {
      documentQuery = (await _store
              .collection("usernames")
              .where("userid", isEqualTo: fbUser.uid)
              .getDocuments())
          .documents;
    } catch (e) {
      _logger.e("_userFromFirebase- Could not contact backend. Error '" +
          e.toString() +
          "'");
      return Future.error(e.toString());
    }

    if (documentQuery.isEmpty) {
      _logger.v("_userFromFirebase- no username");
      return User(
          fbUser.uid, fbUser.email, null, null, UserAuthState.NO_USERNAME);
    }
    String username = documentQuery[0].data["displayName"];
    _logger.v("_userFromFirebase- found username ${username}");
    return User(fbUser.uid, fbUser.email, username, null,
        UserAuthState.FULLY_LOGGED_IN);
  }
}
