#!/bin/bash

BUCKET=rotalo-dev-personalize
ROLE=arn:aws:iam::948003242781:role/rotalo-dev-role

aws s3 cp data s3://$BUCKET --recursive --exclude "*" --include "*.csv"

DATASET_GROUP=$(aws personalize create-dataset-group --name rotalo-dev-dataset-group --query "datasetGroupArn" --output text)

INTERACTIONS_SCHEMA=$(aws personalize create-schema --name rotalo-dev-interactions-schema --schema file://data/interactions.json --query "schemaArn" --output text)
ITEMS_SCHEMA=$(aws personalize create-schema --name rotalo-dev-items-schema --schema file://data/items.json --query "schemaArn" --output text)
USERS_SCHEMA=$(aws personalize create-schema --name rotalo-dev-users-schema --schema file://data/users.json --query "schemaArn" --output text)

INTERACTIONS_DATASET=$(aws personalize create-dataset --name rotalo-dev-interactions-dataset --dataset-group-arn $DATASET_GROUP --dataset-type interactions --schema-arn $INTERACTIONS_SCHEMA --query "datasetArn" --output text)
ITEMS_DATASET=$(aws personalize create-dataset --name rotalo-dev-items-dataset --dataset-group-arn $DATASET_GROUP --dataset-type items --schema-arn $ITEMS_SCHEMA --query "datasetArn" --output text)
USERS_DATASET=$(aws personalize create-dataset --name rotalo-dev-users-dataset --dataset-group-arn $DATASET_GROUP --dataset-type users --schema-arn $USERS_SCHEMA --query "datasetArn" --output text) 

aws personalize create-dataset-import-job --job-name rotalo-dev-interactions-import-job --dataset-arn $INTERACTIONS_DATASET --data-source dataLocation=s3://$BUCKET/filteredInteractions.csv --role-arn $ROLE --query "datasetImportJobArn" --output text
aws personalize create-dataset-import-job --job-name rotalo-dev-items-import-job --dataset-arn $ITEMS_DATASET --data-source dataLocation=s3://$BUCKET/filteredProducts.csv --role-arn $ROLE --query "datasetImportJobArn" --output text
aws personalize create-dataset-import-job --job-name rotalo-dev-users-import-job --dataset-arn $USERS_DATASET --data-source dataLocation=s3://$BUCKET/filteredUsers.csv --role-arn $ROLE --query "datasetImportJobArn" --output text

aws personalize create-event-tracker --name rotalo-dev-event-tracker --dataset-group-arn $DATASET_GROUP --query "eventTrackerArn" --output text

SOLUTION=$(aws personalize create-solution --name rotalo-dev-solution --dataset-group-arn $DATASET_GROUP --perform-auto-ml \
--solution-config '{
  "autoMLConfig": {
    "metricName": "precision_at_10",
    "recipeList": [
      "arn:aws:personalize:::recipe/aws-hrnn",
      "arn:aws:personalize:::recipe/aws-hrnn-metadata"
    ]
  }
}' --query "solutionArn" --output text)

SOLUTION_VERSION=$(aws personalize create-solution-version --solution-arn $SOLUTION --query "solutionVersionArn" --output text)

CAMPAIGN=$(aws personalize create-campaign --name rotalo-dev-campaign --solution-version-arn $SOLUTION_VERSION --min-provisioned-tps 1 --query "campaignArn" --output text)

echo $CAMPAIGN