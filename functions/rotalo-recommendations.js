require('dotenv').config();

const AWS = require("aws-sdk");

const userIds = ["22372", "22453"];
const numResults = 10;

const personalize = new AWS.PersonalizeRuntime({
    region: "us-east-1",
    apiVersion: "2018-05-22"
});

const promises = userIds.map(userId =>
    personalize
        .getRecommendations({
            campaignArn: process.env.RECOMMENDATIONS_CAMPAIGN_ARN,
            userId,
            numResults
        })
        .promise()
);

Promise.all(promises)
    .then(recommendations =>
        recommendations.map(({ itemList }, i) => {
            return {
                userId: userIds[i],
                recommendations: itemList.map(({ itemId }) => itemId)
            };
        })
    )
    .then(response => {
        console.log(JSON.stringify(response, null, 2));
    });
