# VARIABLES #
COSMOS_FUNCTION_PROJECT="code/functions/cosmos_function/cosmos_function.csproj"
DATE_FUNCTION_PROJECT="code/functions/date_function/date_function.csproj"
STAGING_DIRECTORY="staging"
COSMOS_FUNCTION_NAME="COSMOS_FUNCTION_NAME"
DATE_FUNCTION_NAME="DATE_FUNCTION_NAME"
RESOURCE_GROUP="microservices-rg"

# PUBLISH #
dotnet publish $COSMOS_FUNCTION_PROJECT \
--configuration Release \
--output "$STAGING_DIRECTORY/cosmos"

dotnet publish $DATE_FUNCTION_PROJECT \
--configuration Release \
--output "$STAGING_DIRECTORY/date"

# ZIP #
zip -r "$STAGING_DIRECTORY/cosmos.zip" "$STAGING_DIRECTORY/cosmos/" 
zip -r "$STAGING_DIRECTORY/date.zip" "$STAGING_DIRECTORY/date/"

# DEPLOY #
az functionapp deployment source config-zip \
-g $RESOURCE_GROUP \
-n $COSMOS_FUNCTION_NAME \
--src "$STAGING_DIRECTORY/cosmos.zip"

az functionapp deployment source config-zip \
-g $RESOURCE_GROUP \
-n $DATE_FUNCTION_NAME \
--src "$STAGING_DIRECTORY/date.zip"

# TEARDOWN #
rm -rf $STAGING_DIRECTORY