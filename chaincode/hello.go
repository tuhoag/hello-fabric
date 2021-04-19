package chaincode

import (
	"encoding/json"
	"fmt"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// SmartContract provides functions for managing an Asset
type SmartContract struct {
	contractapi.Contract
}

// Asset describes basic details of what makes up a simple asset
type Asset struct {
	ID    string `json:"ID"`
	Value int    `json:value`
	Owner string `json:"owner"`
}


// InitLedger adds a base set of assets to the ledger
func (s *SmartContract) InitLedger(ctx contractapi.TransactionContextInterface) error {
	assets := []Asset{
		{ID: "asset1", Value: 5, Owner: "Tomoko"},
		{ID: "asset2", Value: 5, Owner: "Brad"},
		{ID: "asset3", Value: 10, Owner: "Jin Soo"},
		{ID: "asset4", Value: 10, Owner: "Max"},
		{ID: "asset5", Value: 15, Owner: "Adriana"},
		{ID: "asset6", Value: 15, Owner: "Michel"},
	}

	for _, asset := range assets {
		assetJSON, err := json.Marshal(asset)
		if err != nil {
			return err
		}

		err = ctx.GetStub().PutState(asset.ID, assetJSON)
		if err != nil {
			return fmt.Errorf("failed to put to world state. %v", err)
		}
	}

	return nil
}

// CreateAsset issues a new asset to the world state with given details.
// func (s *SmartContract) CreateAsset(ctx contractapi.TransactionContextInterface, id string, value int, owner string) error {
// 	exists, err := s.AssetExists(ctx, id)
// 	if err != nil {
// 		return err
// 	}
// 	if exists {
// 		return fmt.Errorf("the asset %s already exists", id)
// 	}

// 	asset := Asset{
// 		ID:             id,
// 		Value:          value,
// 		Owner:          owner,
// 	}
// 	assetJSON, err := json.Marshal(asset)
// 	if err != nil {
// 		return err
// 	}

// 	return ctx.GetStub().PutState(id, assetJSON)
// }
