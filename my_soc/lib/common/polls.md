# Group Polling — Final Firestore Schema

Design constraints this schema was built for:
- Client-side only (no Cloud Functions)
- Multi-select voting allowed
- Users can change their vote until poll expiry
- Nested under `societies` (multi-tenant)
- Concurrency correctness handled, but not hardened for adversarial abuse (portfolio-project trade-off, called out explicitly below)

---

## 1. Structure

```
collections(polls)
    ├── title: string
    ├── description: string
    |-- buildingId: String
    ├── createdBy: userId
    ├── createdAt: timestamp
    ├── expiresAt: timestamp
    ├── allowMultipleSelections: boolean
    ├── isAnonymous: boolean
    ├── options: [
    │     { optionId: "opt1", text: "Yes, install it" },
    │     { optionId: "opt2", text: "No, not needed" },
    │     { optionId: "opt3", text: "Need more info" }
    │   ]
    ├── optionCounts: {
    │     "opt1": 0,
    │     "opt2": 0,
    │     "opt3": 0
    │   }
    ├── totalVotes: 0
    └── votes (subcollection)
          └── {userId}                    ← doc ID = voter's UID (prevents duplicate vote docs)
                ├── selectedOptionIds: ["opt1", "opt3"]
                ├── votedAt: timestamp
                └── updatedAt: timestamp
```

## 2. Why each design choice was made

| Decision | Reason |
|---|---|
| `options` is an **array** on the poll doc | Read once with the poll — no extra query to render choices |
| `optionCounts` is a **map**, not baked into the `options` array | Map keys support Firestore dot-notation (`optionCounts.opt1`) so counts can be atomically incremented without reading the doc first |
| Vote doc ID = `userId` | Firestore enforces one doc per user per poll automatically — no way to accidentally create two vote records |
| Vote diffing happens in a **transaction** | Even without concurrent users, this guarantees your own "old vote → new vote" read is consistent with what you write, so change-vote math never drifts |
| `status` field, not just relying on `expiresAt` | Lets you close a poll early, and gives your security rules a simple boolean-like check instead of doing timestamp comparisons everywhere |

## 3. Vote read/write logic (client-side, Flutter)

```dart
Future<void> castOrUpdateVote({
  required String societyId,
  required String pollId,
  required String userId,
  required List<String> newSelectedOptionIds,
}) async {
  final pollRef = FirebaseFirestore.instance
      .collection('societies').doc(societyId)
      .collection('polls').doc(pollId);
  final voteRef = pollRef.collection('votes').doc(userId);

  await FirebaseFirestore.instance.runTransaction((tx) async {
    final pollSnap = await tx.get(pollRef);
    final voteSnap = await tx.get(voteRef);

    if (pollSnap['status'] != 'active') {
      throw Exception('Poll is closed');
    }
    final expiresAt = (pollSnap['expiresAt'] as Timestamp).toDate();
    if (DateTime.now().isAfter(expiresAt)) {
      throw Exception('Poll has expired');
    }

    final oldSelectedOptionIds = voteSnap.exists
        ? List<String>.from(voteSnap['selectedOptionIds'])
        : <String>[];

    final added = newSelectedOptionIds.where((id) => !oldSelectedOptionIds.contains(id));
    final removed = oldSelectedOptionIds.where((id) => !newSelectedOptionIds.contains(id));

    final Map<String, dynamic> countUpdates = {};
    for (final id in added) {
      countUpdates['optionCounts.$id'] = FieldValue.increment(1);
    }
    for (final id in removed) {
      countUpdates['optionCounts.$id'] = FieldValue.increment(-1);
    }
    countUpdates['totalVotes'] = FieldValue.increment(added.length - removed.length);

    tx.update(pollRef, countUpdates);
    tx.set(voteRef, {
      'selectedOptionIds': newSelectedOptionIds,
      'votedAt': voteSnap.exists ? voteSnap['votedAt'] : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  });
}
```
