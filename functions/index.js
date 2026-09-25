const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.sendLessonNotification = functions.firestore
    .document("courses/{courseId}/lessons/{lessonId}")
    .onCreate(async (snapshot, context) => {
      const lessonData = snapshot.data();
      const courseId = context.params.courseId;

      // 1. Căutăm elevii aprobați pentru acest curs
      const enrollments = await admin.firestore()
          .collection("enrollments")
          .where("courseId", "==", courseId)
          .where("status", "==", "approved")
          .get();

      const userIds = enrollments.docs.map((doc) => doc.data().userId);
      if (userIds.length === 0) return null;

      // 2. Extragerea token-urilor FCM ale elevilor
      const userDocs = await admin.firestore()
          .collection("users")
          .where(admin.firestore.FieldPath.documentId(), "in", userIds)
          .get();

      const tokens = [];
      userDocs.forEach((doc) => {
        const token = doc.data().fcmToken;
        if (token) tokens.push(token);
      });

      if (tokens.length === 0) return null;

      // 3. Trimiterea notificării Push prin API V1 pe ecranul blocat
      const message = {
        notification: {
          title: "Lecție nouă!",
          body: `A fost adăugată lecția: "${lessonData.title}"`,
        },
        tokens: tokens,
      };

      return admin.messaging().sendEachForMulticast(message);
    });