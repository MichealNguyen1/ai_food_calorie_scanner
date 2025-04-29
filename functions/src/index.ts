/* eslint-disable */

const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();
const vision = require('@google-cloud/vision');
const client = new vision.ImageAnnotatorClient();

exports.analyzeFood = functions.https.onCall(
  async (data: { imageUrl: string }, context: any) => {
    try {
      const imageUrl = data.imageUrl;
      if (!imageUrl) {
        throw new functions.https.HttpsError('invalid-argument', 'Missing imageUrl');
      }

      // Detect object trong ảnh
      const [objectResult] = await client.objectLocalization(imageUrl);
      const [labelResult] = await client.labelDetection(imageUrl);

      const objects = objectResult.localizedObjectAnnotations || [];
      const labels = labelResult.labelAnnotations || [];

      if (objects.length === 0) {
        throw new functions.https.HttpsError('not-found', 'No objects detected.');
      }

      console.log('Detected objects:', objects.map((obj: any) => obj.name));
      console.log('Detected labels:', labels.map((label: any) => label.description));

      const detectedFoods = [];

      // List label chi tiết món ăn
      const foodLabels = labels.filter((label: any) => {
        const desc = label.description.toLowerCase();
        return desc.includes('chicken') || desc.includes('burger') || desc.includes('ice cream') || desc.includes('pizza') || desc.includes('salad') || desc.includes('sushi') || desc.includes('steak') || desc.includes('spaghetti') || desc.includes('pasta');
      });

      for (const object of objects) {
        let name = object.name.toLowerCase();
        
        if (name === 'food' && foodLabels.length > 0) {
          name = foodLabels[0].description.toLowerCase();
        }

        const foodInfo = mapLabelToFoodInfo(name);

        detectedFoods.push({
          ...foodInfo,
          score: object.score,
          boundingPoly: object.boundingPoly, // Vị trí box object
        });
      }

      return {
        foods: detectedFoods,
        imageUrl: imageUrl,
      };
    } catch (error) {
      console.error(error);
      throw new functions.https.HttpsError(
        "internal",
        "An error occurred while processing the request.",
        error
      );
    }
  }
);

// Ánh xạ label -> Nutrition info
function mapLabelToFoodInfo(label: any) {
  label = label.toLowerCase();

  if (label.includes('salmon')) {
    return { name: "Cá hồi nướng", calories: 280, fat: "12g", protein: "39g", carbs: "0g" };
  } else if (label.includes('salad')) {
    return { name: "Salad gà", calories: 300, fat: "15g", protein: "28g", carbs: "10g" };
  } else if (label.includes('burger')) {
    return { name: "Bánh mì kẹp thịt bò", calories: 550, fat: "32g", protein: "30g", carbs: "40g" };
  } else if (label.includes('pizza')) {
    return { name: "Pizza", calories: 320, fat: "14g", protein: "15g", carbs: "36g" };
  } else if (label.includes('sushi')) {
    return { name: "Sushi", calories: 210, fat: "7g", protein: "9g", carbs: "28g" };
  } else if (label.includes('steak')) {
    return { name: "Bít tết bò", calories: 450, fat: "28g", protein: "40g", carbs: "0g" };
  } else if (label.includes('spaghetti') || label.includes('pasta')) {
    return { name: "Mỳ Ý sốt bò", calories: 470, fat: "17g", protein: "20g", carbs: "58g" };
  } else if (label.includes('chicken') || label.includes('drumstick')) {
    return { name: "Gà rán", calories: 380, fat: "24g", protein: "28g", carbs: "10g" };
  } else if (label.includes('ice cream')) {
    return { name: "Kem", calories: 220, fat: "11g", protein: "4g", carbs: "28g" };
  } else {
    return { name: label, calories: 500, fat: "20g", protein: "25g", carbs: "50g" };
  }
}
