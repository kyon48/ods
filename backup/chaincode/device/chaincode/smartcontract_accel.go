package chaincode

import (
	"bytes"
	"encoding/gob"
	"fmt"

	"github.com/hyperledger/fabric-chaincode-go/shim"
	"github.com/hyperledger/fabric-contract-api-go/contractapi"
	pb "github.com/hyperledger/fabric-protos-go/peer"
)

type SmartContract struct {
	contractapi.Contract
}

type Device struct {
	Pi  string `json:"pi"`
	Ri  string `json:"ri"`
	Cs  string `json:"cs"`
	Cr  string `json:"cr"`
	Con string `json:"con"`
}

type EncryptString struct {
	KeyString string
}

func (s *SmartContract) Init(ctx contractapi.TransactionContextInterface) pb.Response {
	return shim.Success(nil)
}

func (s *SmartContract) Invoke(ctx contractapi.TransactionContextInterface) pb.Response {
	fnc := string(ctx.GetStub().GetArgs()[0])
	switch fnc {
	case "createDevice":
		return Invoke(ctx, s.createDevice)
	case "queryDevice":
		return Invoke(ctx, s.queryDevice)
	case "getHistory":
		return Invoke(ctx, s.getHistory)
	}
	return shim.Error("Unknown action, check the first argument, must be one of 'insert', 'query'")
}

func (s *SmartContract) createDevice(ctx contractapi.TransactionContextInterface, args []string) pb.Response {
	if err := ctx.GetStub().PutState(args[0], []byte(args[1])); err != nil {
		return shim.Error(err.Error())
	} else {
		return shim.Success(nil)
	}
}

func (s *SmartContract) queryDevice(ctx contractapi.TransactionContextInterface, args []string) pb.Response {
	if value, err := ctx.GetStub().GetState(args[0]); err != nil {
		return shim.Error(err.Error())
	} else {
		return shim.Success(value)
	}
}

func (s *SmartContract) getHistory(ctx contractapi.TransactionContextInterface, args []string) pb.Response {
	if len(args) != 1 {
		return shim.Error("invalid number of arguments")
	}
	deviceID := args[0]
	fmt.Println("deviceID: " + deviceID)

	iterator, err := ctx.GetStub().GetHistoryForKey(deviceID)
	if err != nil {
		return shim.Error(err.Error())
	}

	defer iterator.Close()

	// buffer is a JSON array containing QueryResults
	var buffer bytes.Buffer
	buffer.WriteString("[")
	bArrayMemberAlreadyWritten := false
	for iterator.HasNext() {
		queryResponse, err := iterator.Next()
		if err != nil {
			shim.Error(err.Error())
		}
		// Add a comma before array members, suppress it for the first array member
		if bArrayMemberAlreadyWritten {
			buffer.WriteString(",")
		}
		buffer.WriteString("{\"TxId\":")
		buffer.WriteString("\"")
		buffer.WriteString(queryResponse.TxId)
		buffer.WriteString("\"")

		buffer.WriteString(", \"Value\":")
		// if it was a delete operation on given key, then we need to set the
		//corresponding value null. Else, we will write the response.Value
		if queryResponse.IsDelete {
			buffer.WriteString("null")
		} else {
			buffer.WriteString(string(queryResponse.Value))
		}
		buffer.WriteString("}")
		bArrayMemberAlreadyWritten = true
	}
	buffer.WriteString("]")

	fmt.Printf("getHistory:\n%s\n", buffer.String())

	return shim.Success(buffer.Bytes())
}

func Invoke(ctx contractapi.TransactionContextInterface, target func(contractapi.TransactionContextInterface, []string) pb.Response) pb.Response {
	items := make([][][]byte, 0)
	if err := decode(ctx.GetStub().GetArgs()[1], &items); err != nil {
		return shim.Error("Failed to unmarshal request")
	}

	itemSize := len(items)
	payloads := make([][]byte, itemSize, itemSize)
	for i, item := range items {
		argsSize := len(item)
		args := make([]string, argsSize, argsSize)
		for j, arg := range item {
			args[j] = string(arg)
		}

		result := target(ctx, args)
		if result.Status == shim.ERROR {
			return shim.Error("Failed to invoke: " + result.Message)
		}
		payloads[i] = result.Payload
	}

	response, err := encode(payloads)
	if err != nil {
		return shim.Error("Failed to marshal response")
	}
	return shim.Success(response)
}

func encode(v interface{}) ([]byte, error) {
	buf := new(bytes.Buffer)
	if err := gob.NewEncoder(buf).Encode(v); err != nil {
		return nil, err
	}
	return buf.Bytes(), nil
}

func decode(d []byte, v interface{}) error {
	buf := bytes.NewBuffer(d)
	if err := gob.NewDecoder(buf).Decode(v); err != nil {
		return err
	}
	return nil
}
