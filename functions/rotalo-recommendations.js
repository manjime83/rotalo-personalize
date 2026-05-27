require("dotenv").config();

const {
  PersonalizeRuntimeClient,
  GetRecommendationsCommand,
} = require("@aws-sdk/client-personalize-runtime");

const userIds = ["22372", "22453"];
const numResults = 10;

const personalize = new PersonalizeRuntimeClient({ region: "us-east-1" });

const promises = userIds.map((userId) =>
  personalize.send(
    new GetRecommendationsCommand({
      campaignArn: process.env.RECOMMENDATIONS_CAMPAIGN_ARN,
      userId,
      numResults,
    }),
  ),
);

Promise.all(promises)
  .then((recommendations) =>
    recommendations.map(({ itemList }, i) => {
      return {
        userId: userIds[i],
        recommendations: itemList.map(({ itemId }) => itemId),
      };
    }),
  )
  .then((response) => {
    console.log(JSON.stringify(response, null, 2));
  });
